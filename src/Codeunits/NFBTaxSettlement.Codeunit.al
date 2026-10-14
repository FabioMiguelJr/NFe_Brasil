codeunit 50125 "NFB Tax Settlement"
{
    // Monthly settlement (apuração) of the taxes posted by NFB Tax Posting.
    // Calculate reads the tax lines of the posted invoices and credit memos of the month, using the same rules
    // NFB Tax Posting used to post them, so the settlement matches the balances of the tax accounts:
    // - output tax: sales whose operation type posts taxes, for taxes with a payable account
    //   (and a sales deduction account when the tax is included in the price);
    // - input tax: purchases whose operation type posts taxes, for taxes with a recoverable account.
    // Post clears the period: debits the payable account, credits the recoverable account with the credits used,
    // posts the manual adjustments and creates the payable (vendor ledger entry) of the guide for the amount due.
    // A remaining credit stays in the recoverable account and is carried to the next settlement.

    var
        NotCalculatedErr: Label 'Calculate the settlement before posting it.';
        PeriodUsedErr: Label 'Settlement %1 already covers %2..%3.', Comment = '%1 = settlement no., %2 = starting date, %3 = ending date';
        EarlierOpenErr: Label 'Settlement %1 of an earlier period is still open. Post it first, so its credit carried forward is known.', Comment = '%1 = settlement no.';
        RecalculateErr: Label 'Settlement %1 was posted after this settlement was calculated. Calculate again before posting.', Comment = '%1 = settlement no.';
        LaterSettlementErr: Label 'Settlement %1 of a later period is already posted. Reopen it first.', Comment = '%1 = settlement no.';
        NoLinesErr: Label 'There is nothing to post in settlement %1.', Comment = '%1 = settlement no.';
        AccountMissingErr: Label '%1 for %2 must be filled in NF-e Tax Posting Setup to post settlement line %3 %4.', Comment = '%1 = field caption, %2 = tax type, %3 = tax type, %4 = state';
        NotReversedErr: Label 'The entries of settlement %1 are still in the general ledger. Reverse G/L register %2 (G/L Registers, Reverse Register) and then reopen the settlement.', Comment = '%1 = settlement no., %2 = register no.';
        PostConfirmQst: Label 'Post settlement %1? The tax accounts are cleared and %2 payables are created for a total of %3.', Comment = '%1 = settlement no., %2 = number of payables, %3 = amount';
        PostedMsg: Label 'Settlement %1 was posted. %2 payables were created.', Comment = '%1 = settlement no., %2 = count';
        CalculatedMsg: Label 'Settlement %1 was calculated: %2 tax lines from %3 documents.', Comment = '%1 = settlement no., %2 = lines, %3 = documents';
        GLDescriptionTxt: Label '%1 %2 settlement %3', Comment = '%1 = tax type, %2 = state, %3 = month/year';
        VendorDescriptionTxt: Label '%1 %2 %3 %4', Locked = true;
        ExtDocNoTxt: Label '%1-%2%3', Locked = true;
        DocumentCount: Integer;

    procedure Calculate(var NFBTaxSettlementHeader: Record "NFB Tax Settlement Header")
    var
        TempSavedLine: Record "NFB Tax Settlement Line" temporary;
        NFBTaxSettlementLine: Record "NFB Tax Settlement Line";
        NFBTaxSettlementEntry: Record "NFB Tax Settlement Entry";
        PreviousHeader: Record "NFB Tax Settlement Header";
        HasPrevious: Boolean;
    begin
        NFBTaxSettlementHeader.TestStatusOpen();
        NFBTaxSettlementHeader.TestField("Starting Date");
        NFBTaxSettlementHeader.TestField("Ending Date");
        CheckPeriod(NFBTaxSettlementHeader);

        NFBTaxSettlementLine.SetRange("Settlement No.", NFBTaxSettlementHeader."No.");
        if NFBTaxSettlementLine.FindSet() then
            repeat
                TempSavedLine := NFBTaxSettlementLine;
                TempSavedLine.Insert();
            until NFBTaxSettlementLine.Next() = 0;
        NFBTaxSettlementLine.DeleteAll();
        NFBTaxSettlementEntry.SetRange("Settlement No.", NFBTaxSettlementHeader."No.");
        NFBTaxSettlementEntry.DeleteAll();

        DocumentCount := 0;
        AddSalesInvoices(NFBTaxSettlementHeader);
        AddSalesCrMemos(NFBTaxSettlementHeader);
        AddPurchaseInvoices(NFBTaxSettlementHeader);
        AddPurchaseCrMemos(NFBTaxSettlementHeader);

        HasPrevious := FindPreviousSettlement(NFBTaxSettlementHeader, PreviousHeader);
        if HasPrevious then
            AddCarriedForwardLines(NFBTaxSettlementHeader, PreviousHeader);
        AddSavedManualLines(NFBTaxSettlementHeader, TempSavedLine, HasPrevious);

        NFBTaxSettlementLine.Reset();
        NFBTaxSettlementLine.SetRange("Settlement No.", NFBTaxSettlementHeader."No.");
        if NFBTaxSettlementLine.FindSet() then
            repeat
                CompleteLine(NFBTaxSettlementHeader, NFBTaxSettlementLine, TempSavedLine, PreviousHeader, HasPrevious);
                NFBTaxSettlementLine.Modify();
            until NFBTaxSettlementLine.Next() = 0;

        NFBTaxSettlementHeader."Calculated At" := CurrentDateTime();
        NFBTaxSettlementHeader.Modify();
        if GuiAllowed() then
            Message(CalculatedMsg, NFBTaxSettlementHeader."No.", NFBTaxSettlementLine.Count(), DocumentCount);
    end;

    procedure Post(var NFBTaxSettlementHeader: Record "NFB Tax Settlement Header")
    var
        NFBTaxSettlementLine: Record "NFB Tax Settlement Line";
        NFBSetup: Record "NFB Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        PreviousHeader: Record "NFB Tax Settlement Header";
        PayableCount: Integer;
    begin
        NFBTaxSettlementHeader.LockTable();
        NFBTaxSettlementHeader.Get(NFBTaxSettlementHeader."No.");
        NFBTaxSettlementHeader.TestStatusOpen();
        NFBTaxSettlementHeader.TestField("Posting Date");
        if NFBTaxSettlementHeader."Calculated At" = 0DT then
            Error(NotCalculatedErr);
        CheckPeriod(NFBTaxSettlementHeader);
        // The carried credit must come from the settlement that is posted now.
        if FindPreviousSettlement(NFBTaxSettlementHeader, PreviousHeader) then
            if PreviousHeader."Posted At" > NFBTaxSettlementHeader."Calculated At" then
                Error(RecalculateErr, PreviousHeader."No.");
        NFBSetup.Get();
        NFBSetup.TestField("Settlement Jnl. Template");
        NFBSetup.TestField("Settlement Jnl. Batch");
        GenJournalTemplate.Get(NFBSetup."Settlement Jnl. Template");
        GenJournalBatch.Get(NFBSetup."Settlement Jnl. Template", NFBSetup."Settlement Jnl. Batch");

        NFBTaxSettlementLine.SetRange("Settlement No.", NFBTaxSettlementHeader."No.");
        if NFBTaxSettlementLine.IsEmpty() then
            Error(NoLinesErr, NFBTaxSettlementHeader."No.");
        NFBTaxSettlementLine.FindSet();
        repeat
            NFBTaxSettlementLine.UpdateBalance();
            NFBTaxSettlementLine.Modify();
            CheckLine(NFBTaxSettlementLine);
            if NFBTaxSettlementLine."Amount Payable" > 0 then
                PayableCount += 1;
        until NFBTaxSettlementLine.Next() = 0;

        if GuiAllowed() then begin
            NFBTaxSettlementHeader.CalcFields("Total Payable");
            if not Confirm(PostConfirmQst, false, NFBTaxSettlementHeader."No.", PayableCount, Format(NFBTaxSettlementHeader."Total Payable", 0, '<Precision,2:2><Standard Format,0>')) then
                exit;
        end;

        NFBTaxSettlementLine.FindSet(true);
        repeat
            PostLine(NFBTaxSettlementHeader, NFBTaxSettlementLine, GenJournalTemplate, GenJournalBatch, GenJnlPostLine);
            NFBTaxSettlementLine.Modify();
        until NFBTaxSettlementLine.Next() = 0;

        NFBTaxSettlementHeader.Status := NFBTaxSettlementHeader.Status::Posted;
        NFBTaxSettlementHeader."Posted At" := CurrentDateTime();
        NFBTaxSettlementHeader."Posted By" := CopyStr(UserId(), 1, MaxStrLen(NFBTaxSettlementHeader."Posted By"));
        NFBTaxSettlementHeader.Modify();
        if GuiAllowed() then
            Message(PostedMsg, NFBTaxSettlementHeader."No.", PayableCount);
    end;

    /// <summary>
    /// Reopens a posted settlement after its G/L register was reversed with the standard Reverse Register.
    /// </summary>
    procedure Reopen(var NFBTaxSettlementHeader: Record "NFB Tax Settlement Header")
    var
        NFBTaxSettlementLine: Record "NFB Tax Settlement Line";
        LaterHeader: Record "NFB Tax Settlement Header";
        GLEntry: Record "G/L Entry";
    begin
        NFBTaxSettlementHeader.TestField(Status, NFBTaxSettlementHeader.Status::Posted);
        LaterHeader.SetRange(Status, LaterHeader.Status::Posted);
        LaterHeader.SetFilter("Starting Date", '>%1', NFBTaxSettlementHeader."Ending Date");
        if LaterHeader.FindFirst() then
            Error(LaterSettlementErr, LaterHeader."No.");
        GLEntry.SetRange("Document No.", NFBTaxSettlementHeader."No.");
        GLEntry.SetRange("Posting Date", NFBTaxSettlementHeader."Posting Date");
        GLEntry.SetRange(Reversed, false);
        if GLEntry.FindFirst() then
            Error(NotReversedErr, NFBTaxSettlementHeader."No.", FindRegisterNo(GLEntry."Entry No."));

        NFBTaxSettlementHeader.Status := NFBTaxSettlementHeader.Status::Open;
        NFBTaxSettlementHeader."Posted At" := 0DT;
        NFBTaxSettlementHeader."Posted By" := '';
        NFBTaxSettlementHeader.Modify();
        NFBTaxSettlementLine.SetRange("Settlement No.", NFBTaxSettlementHeader."No.");
        NFBTaxSettlementLine.ModifyAll("Vendor Ledger Entry No.", 0);
        // Later open settlements used the credit of this one and must be calculated again.
        LaterHeader.Reset();
        LaterHeader.SetRange(Status, LaterHeader.Status::Open);
        LaterHeader.SetFilter("Starting Date", '>%1', NFBTaxSettlementHeader."Ending Date");
        LaterHeader.ModifyAll("Calculated At", 0DT);
    end;

    procedure ShowPayables(NFBTaxSettlementHeader: Record "NFB Tax Settlement Header")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Document No.", NFBTaxSettlementHeader."No.");
        VendorLedgerEntry.SetRange("Posting Date", NFBTaxSettlementHeader."Posting Date");
        Page.Run(Page::"Vendor Ledger Entries", VendorLedgerEntry);
    end;

    // Calculation

    local procedure AddSalesInvoices(NFBTaxSettlementHeader: Record "NFB Tax Settlement Header")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Posting Date", NFBTaxSettlementHeader."Starting Date", NFBTaxSettlementHeader."Ending Date");
        SalesInvoiceHeader.SetFilter("NFB Operation Type", '<>%1', '');
        if SalesInvoiceHeader.FindSet() then
            repeat
                if PostsTaxes(SalesInvoiceHeader."NFB Operation Type") then
                    AddDocument(NFBTaxSettlementHeader, Database::"Sales Invoice Line", "NFB Source Doc. Type"::"Sales Invoice",
                        SalesInvoiceHeader."No.", SalesInvoiceHeader."Posting Date", SalesInvoiceHeader."Sell-to Customer No.", 1, true,
                        GetRecipientUF(SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."Bill-to Customer No.", SalesInvoiceHeader."Ship-to Code"),
                        GetIssuerUF(SalesInvoiceHeader."Location Code"));
            until SalesInvoiceHeader.Next() = 0;
    end;

    local procedure AddSalesCrMemos(NFBTaxSettlementHeader: Record "NFB Tax Settlement Header")
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.SetRange("Posting Date", NFBTaxSettlementHeader."Starting Date", NFBTaxSettlementHeader."Ending Date");
        SalesCrMemoHeader.SetFilter("NFB Operation Type", '<>%1', '');
        if SalesCrMemoHeader.FindSet() then
            repeat
                if PostsTaxes(SalesCrMemoHeader."NFB Operation Type") then
                    AddDocument(NFBTaxSettlementHeader, Database::"Sales Cr.Memo Line", "NFB Source Doc. Type"::"Sales Cr. Memo",
                        SalesCrMemoHeader."No.", SalesCrMemoHeader."Posting Date", SalesCrMemoHeader."Sell-to Customer No.", -1, true,
                        GetRecipientUF(SalesCrMemoHeader."Sell-to Customer No.", SalesCrMemoHeader."Bill-to Customer No.", SalesCrMemoHeader."Ship-to Code"),
                        GetIssuerUF(SalesCrMemoHeader."Location Code"));
            until SalesCrMemoHeader.Next() = 0;
    end;

    local procedure AddPurchaseInvoices(NFBTaxSettlementHeader: Record "NFB Tax Settlement Header")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Posting Date", NFBTaxSettlementHeader."Starting Date", NFBTaxSettlementHeader."Ending Date");
        PurchInvHeader.SetFilter("NFB Operation Type", '<>%1', '');
        if PurchInvHeader.FindSet() then
            repeat
                if PostsTaxes(PurchInvHeader."NFB Operation Type") then
                    AddDocument(NFBTaxSettlementHeader, Database::"Purch. Inv. Line", "NFB Source Doc. Type"::"Purchase Invoice",
                        PurchInvHeader."No.", PurchInvHeader."Posting Date", PurchInvHeader."Buy-from Vendor No.", 1, false, '', '');
            until PurchInvHeader.Next() = 0;
    end;

    local procedure AddPurchaseCrMemos(NFBTaxSettlementHeader: Record "NFB Tax Settlement Header")
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr.SetRange("Posting Date", NFBTaxSettlementHeader."Starting Date", NFBTaxSettlementHeader."Ending Date");
        PurchCrMemoHdr.SetFilter("NFB Operation Type", '<>%1', '');
        if PurchCrMemoHdr.FindSet() then
            repeat
                if PostsTaxes(PurchCrMemoHdr."NFB Operation Type") then
                    AddDocument(NFBTaxSettlementHeader, Database::"Purch. Cr. Memo Line", "NFB Source Doc. Type"::"Purchase Cr. Memo",
                        PurchCrMemoHdr."No.", PurchCrMemoHdr."Posting Date", PurchCrMemoHdr."Buy-from Vendor No.", -1, false, '', '');
            until PurchCrMemoHdr.Next() = 0;
    end;

    local procedure AddDocument(NFBTaxSettlementHeader: Record "NFB Tax Settlement Header"; TableID: Integer; SourceDocType: Enum "NFB Source Doc. Type"; DocumentNo: Code[20]; PostingDate: Date; SourceNo: Code[20]; Sign: Integer; IsSales: Boolean; RecipientUF: Code[2]; IssuerUF: Code[2])
    var
        NFBTaxLine: Record "NFB Tax Line";
        StateCode: Code[2];
        Counted: Boolean;
    begin
        NFBTaxLine.SetRange("Table ID", TableID);
        NFBTaxLine.SetRange("Document Type", 0);
        NFBTaxLine.SetRange("Document No.", DocumentNo);
        if NFBTaxLine.FindSet() then
            repeat
                if NFBTaxLine.Amount <> 0 then
                    if (IsSales and CountsAsOutput(NFBTaxLine."Tax Type")) or ((not IsSales) and CountsAsInput(NFBTaxLine."Tax Type")) then begin
                        StateCode := '';
                        if IsSales and IsOwedToDestination(NFBTaxLine."Tax Type") and (RecipientUF <> '') and (RecipientUF <> IssuerUF) then
                            StateCode := RecipientUF;
                        AddAmount(NFBTaxSettlementHeader, SourceDocType, DocumentNo, PostingDate, SourceNo, NFBTaxLine."Tax Type", StateCode,
                            Sign * NFBTaxLine."Base Amount", Sign * NFBTaxLine.Amount, IsSales);
                        Counted := true;
                    end;
            until NFBTaxLine.Next() = 0;
        if Counted then
            DocumentCount += 1;
    end;

    local procedure AddAmount(NFBTaxSettlementHeader: Record "NFB Tax Settlement Header"; SourceDocType: Enum "NFB Source Doc. Type"; DocumentNo: Code[20]; PostingDate: Date; SourceNo: Code[20]; TaxType: Enum "NFB Tax Type"; StateCode: Code[2]; BaseAmount: Decimal; TaxAmount: Decimal; IsSales: Boolean)
    var
        NFBTaxSettlementEntry: Record "NFB Tax Settlement Entry";
        NFBTaxSettlementLine: Record "NFB Tax Settlement Line";
    begin
        NFBTaxSettlementEntry.SetCurrentKey("Settlement No.", "Source Doc. Type", "Document No.", "Tax Type", "State Code");
        NFBTaxSettlementEntry.SetRange("Settlement No.", NFBTaxSettlementHeader."No.");
        NFBTaxSettlementEntry.SetRange("Source Doc. Type", SourceDocType);
        NFBTaxSettlementEntry.SetRange("Document No.", DocumentNo);
        NFBTaxSettlementEntry.SetRange("Tax Type", TaxType);
        NFBTaxSettlementEntry.SetRange("State Code", StateCode);
        if not NFBTaxSettlementEntry.FindFirst() then begin
            NFBTaxSettlementEntry.Init();
            NFBTaxSettlementEntry."Settlement No." := NFBTaxSettlementHeader."No.";
            NFBTaxSettlementEntry."Entry No." := NextEntryNo(NFBTaxSettlementHeader."No.");
            NFBTaxSettlementEntry."Tax Type" := TaxType;
            NFBTaxSettlementEntry."State Code" := StateCode;
            NFBTaxSettlementEntry."Source Doc. Type" := SourceDocType;
            NFBTaxSettlementEntry."Document No." := DocumentNo;
            NFBTaxSettlementEntry."Posting Date" := PostingDate;
            NFBTaxSettlementEntry."Source No." := SourceNo;
            NFBTaxSettlementEntry.Insert();
        end;
        NFBTaxSettlementEntry."Base Amount" += BaseAmount;
        if IsSales then
            NFBTaxSettlementEntry."Output Tax" += TaxAmount
        else
            NFBTaxSettlementEntry."Input Tax" += TaxAmount;
        NFBTaxSettlementEntry.Modify();

        GetOrInsertLine(NFBTaxSettlementHeader."No.", TaxType, StateCode, NFBTaxSettlementLine);
        if IsSales then
            NFBTaxSettlementLine."Output Tax" += TaxAmount
        else
            NFBTaxSettlementLine."Input Tax" += TaxAmount;
        NFBTaxSettlementLine.Modify();
    end;

    local procedure GetOrInsertLine(SettlementNo: Code[20]; TaxType: Enum "NFB Tax Type"; StateCode: Code[2]; var NFBTaxSettlementLine: Record "NFB Tax Settlement Line")
    begin
        if NFBTaxSettlementLine.Get(SettlementNo, TaxType, StateCode) then
            exit;
        NFBTaxSettlementLine.Init();
        NFBTaxSettlementLine."Settlement No." := SettlementNo;
        NFBTaxSettlementLine."Tax Type" := TaxType;
        NFBTaxSettlementLine."State Code" := StateCode;
        NFBTaxSettlementLine.Insert(true);
    end;

    local procedure NextEntryNo(SettlementNo: Code[20]): Integer
    var
        NFBTaxSettlementEntry: Record "NFB Tax Settlement Entry";
    begin
        NFBTaxSettlementEntry.SetRange("Settlement No.", SettlementNo);
        if NFBTaxSettlementEntry.FindLast() then
            exit(NFBTaxSettlementEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure AddCarriedForwardLines(NFBTaxSettlementHeader: Record "NFB Tax Settlement Header"; PreviousHeader: Record "NFB Tax Settlement Header")
    var
        PreviousLine: Record "NFB Tax Settlement Line";
        NFBTaxSettlementLine: Record "NFB Tax Settlement Line";
    begin
        // A credit keeps flowing even in a month without movement of that tax.
        PreviousLine.SetRange("Settlement No.", PreviousHeader."No.");
        PreviousLine.SetFilter("Credit Carried Forward", '<>0');
        if PreviousLine.FindSet() then
            repeat
                GetOrInsertLine(NFBTaxSettlementHeader."No.", PreviousLine."Tax Type", PreviousLine."State Code", NFBTaxSettlementLine);
            until PreviousLine.Next() = 0;
    end;

    local procedure AddSavedManualLines(NFBTaxSettlementHeader: Record "NFB Tax Settlement Header"; var TempSavedLine: Record "NFB Tax Settlement Line" temporary; HasPrevious: Boolean)
    var
        NFBTaxSettlementLine: Record "NFB Tax Settlement Line";
    begin
        // Keep the lines where the user entered adjustments, or an opening credit in the first settlement.
        TempSavedLine.Reset();
        if TempSavedLine.FindSet() then
            repeat
                if (TempSavedLine."Other Debits" <> 0) or (TempSavedLine."Other Credits" <> 0) or
                   ((not HasPrevious) and (TempSavedLine."Previous Credit Balance" <> 0))
                then
                    GetOrInsertLine(NFBTaxSettlementHeader."No.", TempSavedLine."Tax Type", TempSavedLine."State Code", NFBTaxSettlementLine);
            until TempSavedLine.Next() = 0;
    end;

    local procedure CompleteLine(NFBTaxSettlementHeader: Record "NFB Tax Settlement Header"; var NFBTaxSettlementLine: Record "NFB Tax Settlement Line"; var TempSavedLine: Record "NFB Tax Settlement Line" temporary; PreviousHeader: Record "NFB Tax Settlement Header"; HasPrevious: Boolean)
    var
        PreviousLine: Record "NFB Tax Settlement Line";
        NFBTaxDueDateSetup: Record "NFB Tax Due Date Setup";
        HasSaved: Boolean;
    begin
        HasSaved := TempSavedLine.Get(NFBTaxSettlementLine."Settlement No.", NFBTaxSettlementLine."Tax Type", NFBTaxSettlementLine."State Code");
        if HasSaved then begin
            NFBTaxSettlementLine."Other Debits" := TempSavedLine."Other Debits";
            NFBTaxSettlementLine."Other Credits" := TempSavedLine."Other Credits";
        end;

        NFBTaxSettlementLine."Previous Credit Balance" := 0;
        if HasPrevious then begin
            if PreviousLine.Get(PreviousHeader."No.", NFBTaxSettlementLine."Tax Type", NFBTaxSettlementLine."State Code") then
                NFBTaxSettlementLine."Previous Credit Balance" := PreviousLine."Credit Carried Forward";
        end else
            if HasSaved then
                NFBTaxSettlementLine."Previous Credit Balance" := TempSavedLine."Previous Credit Balance";

        if NFBTaxDueDateSetup.FindForTax(NFBTaxSettlementLine."Tax Type", NFBTaxSettlementLine."State Code") then begin
            NFBTaxSettlementLine."Guide Type" := NFBTaxDueDateSetup."Guide Type";
            NFBTaxSettlementLine."Vendor No." := NFBTaxDueDateSetup."Vendor No.";
            NFBTaxSettlementLine."Revenue Code" := NFBTaxDueDateSetup."Revenue Code";
            NFBTaxSettlementLine."Adjustment Account" := NFBTaxDueDateSetup."Adjustment Account";
            NFBTaxSettlementLine."Due Date" := NFBTaxDueDateSetup.CalcDueDate(NFBTaxSettlementHeader."Ending Date");
        end;
        // Values typed on the line win over a blank setup.
        if HasSaved then begin
            if NFBTaxSettlementLine."Vendor No." = '' then
                NFBTaxSettlementLine."Vendor No." := TempSavedLine."Vendor No.";
            if NFBTaxSettlementLine."Due Date" = 0D then
                NFBTaxSettlementLine."Due Date" := TempSavedLine."Due Date";
            if NFBTaxSettlementLine."Adjustment Account" = '' then
                NFBTaxSettlementLine."Adjustment Account" := TempSavedLine."Adjustment Account";
            if NFBTaxSettlementLine."Revenue Code" = '' then
                NFBTaxSettlementLine."Revenue Code" := TempSavedLine."Revenue Code";
        end;
        NFBTaxSettlementLine.UpdateBalance();
    end;

    local procedure FindPreviousSettlement(NFBTaxSettlementHeader: Record "NFB Tax Settlement Header"; var PreviousHeader: Record "NFB Tax Settlement Header"): Boolean
    begin
        PreviousHeader.SetCurrentKey("Starting Date");
        PreviousHeader.SetRange(Status, PreviousHeader.Status::Posted);
        PreviousHeader.SetFilter("Ending Date", '<%1', NFBTaxSettlementHeader."Starting Date");
        exit(PreviousHeader.FindLast());
    end;

    local procedure CheckPeriod(NFBTaxSettlementHeader: Record "NFB Tax Settlement Header")
    var
        OtherHeader: Record "NFB Tax Settlement Header";
    begin
        OtherHeader.SetFilter("No.", '<>%1', NFBTaxSettlementHeader."No.");
        OtherHeader.SetFilter("Starting Date", '<=%1', NFBTaxSettlementHeader."Ending Date");
        OtherHeader.SetFilter("Ending Date", '>=%1', NFBTaxSettlementHeader."Starting Date");
        if OtherHeader.FindFirst() then
            Error(PeriodUsedErr, OtherHeader."No.", OtherHeader."Starting Date", OtherHeader."Ending Date");
        OtherHeader.Reset();
        OtherHeader.SetRange(Status, OtherHeader.Status::Posted);
        OtherHeader.SetFilter("Starting Date", '>%1', NFBTaxSettlementHeader."Ending Date");
        if OtherHeader.FindFirst() then
            Error(LaterSettlementErr, OtherHeader."No.");
        OtherHeader.SetRange(Status, OtherHeader.Status::Open);
        OtherHeader.SetFilter("Starting Date", '<%1', NFBTaxSettlementHeader."Starting Date");
        if OtherHeader.FindFirst() then
            Error(EarlierOpenErr, OtherHeader."No.");
    end;

    local procedure PostsTaxes(OperationTypeCode: Code[20]): Boolean
    var
        NFBOperationType: Record "NFB Operation Type";
    begin
        if not NFBOperationType.Get(OperationTypeCode) then
            exit(false);
        exit(NFBOperationType."Calculate Taxes" and NFBOperationType."Post Taxes");
    end;

    /// <summary>
    /// Same condition NFB Tax Posting uses to post the tax of a sales document.
    /// </summary>
    local procedure CountsAsOutput(TaxType: Enum "NFB Tax Type"): Boolean
    var
        NFBTaxPostingSetup: Record "NFB Tax Posting Setup";
    begin
        if not NFBTaxPostingSetup.Get(TaxType) then
            exit(false);
        if NFBTaxPostingSetup."Payable Account" = '' then
            exit(false);
        if NFBTaxPostingSetup.IsIncludedInPrice(TaxType) then
            exit(NFBTaxPostingSetup."Sales Deduction Account" <> '');
        exit(true);
    end;

    /// <summary>
    /// Same condition NFB Tax Posting uses to debit the recoverable account on a purchase.
    /// </summary>
    local procedure CountsAsInput(TaxType: Enum "NFB Tax Type"): Boolean
    var
        NFBTaxPostingSetup: Record "NFB Tax Posting Setup";
    begin
        if TaxType = TaxType::II then
            exit(false);
        if not NFBTaxPostingSetup.Get(TaxType) then
            exit(false);
        if NFBTaxPostingSetup."Recoverable Account" = '' then
            exit(false);
        if NFBTaxPostingSetup.IsIncludedInPrice(TaxType) then
            exit(NFBTaxPostingSetup."Purchase Cost Account" <> '');
        exit(true);
    end;

    local procedure IsOwedToDestination(TaxType: Enum "NFB Tax Type"): Boolean
    begin
        exit(TaxType in [TaxType::"ICMS ST", TaxType::"FCP ST", TaxType::DIFAL, TaxType::"FCP Dest."]);
    end;

    /// <summary>
    /// Same rule as NFB Tax Engine: ship-to address UF, otherwise the bill-to customer's UF.
    /// </summary>
    local procedure GetRecipientUF(SellToCustomerNo: Code[20]; BillToCustomerNo: Code[20]; ShipToCode: Code[10]): Code[2]
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
    begin
        if ShipToCode <> '' then
            if ShipToAddress.Get(SellToCustomerNo, ShipToCode) then
                if ShipToAddress."NFB UF" <> '' then
                    exit(ShipToAddress."NFB UF");
        if Customer.Get(BillToCustomerNo) then
            exit(Customer."NFB UF");
    end;

    local procedure GetIssuerUF(LocationCode: Code[10]): Code[2]
    var
        NFBOperationMgt: Codeunit "NFB Operation Mgt";
    begin
        exit(NFBOperationMgt.GetIssuerUF(LocationCode));
    end;

    // Posting

    local procedure CheckLine(NFBTaxSettlementLine: Record "NFB Tax Settlement Line")
    var
        NFBTaxPostingSetup: Record "NFB Tax Posting Setup";
    begin
        if not NFBTaxPostingSetup.Get(NFBTaxSettlementLine."Tax Type") then
            NFBTaxPostingSetup.Init();
        if (NFBTaxSettlementLine."Output Tax" <> 0) and (NFBTaxPostingSetup."Payable Account" = '') then
            Error(AccountMissingErr, NFBTaxPostingSetup.FieldCaption("Payable Account"), NFBTaxSettlementLine."Tax Type", NFBTaxSettlementLine."Tax Type", NFBTaxSettlementLine."State Code");
        if (NFBTaxSettlementLine.CreditsUsed() <> 0) and (NFBTaxPostingSetup."Recoverable Account" = '') then
            Error(AccountMissingErr, NFBTaxPostingSetup.FieldCaption("Recoverable Account"), NFBTaxSettlementLine."Tax Type", NFBTaxSettlementLine."Tax Type", NFBTaxSettlementLine."State Code");
        if NFBTaxSettlementLine."Other Debits" - NFBTaxSettlementLine."Other Credits" <> 0 then
            NFBTaxSettlementLine.TestField("Adjustment Account");
        if NFBTaxSettlementLine."Amount Payable" > 0 then begin
            NFBTaxSettlementLine.TestField("Vendor No.");
            NFBTaxSettlementLine.TestField("Due Date");
        end;
    end;

    local procedure PostLine(NFBTaxSettlementHeader: Record "NFB Tax Settlement Header"; var NFBTaxSettlementLine: Record "NFB Tax Settlement Line"; GenJournalTemplate: Record "Gen. Journal Template"; GenJournalBatch: Record "Gen. Journal Batch"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        NFBTaxPostingSetup: Record "NFB Tax Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GLDescription: Text[100];
        ExternalDocumentNo: Code[35];
    begin
        // Debits: payable account (output tax) and adjustments; credits: recoverable account (credits used) and the vendor (amount due).
        if not NFBTaxPostingSetup.Get(NFBTaxSettlementLine."Tax Type") then
            NFBTaxPostingSetup.Init();
        GLDescription := CopyStr(Squeeze(StrSubstNo(GLDescriptionTxt, NFBTaxSettlementLine."Tax Type", NFBTaxSettlementLine."State Code",
            Format(NFBTaxSettlementHeader."Starting Date", 0, '<Month,2>/<Year4>'))), 1, MaxStrLen(GLDescription));

        if NFBTaxSettlementLine."Output Tax" <> 0 then
            PostGLAccount(NFBTaxSettlementHeader, GenJournalTemplate, GenJournalBatch, NFBTaxPostingSetup."Payable Account", NFBTaxSettlementLine."Output Tax", GLDescription, GenJnlPostLine);
        if NFBTaxSettlementLine."Other Debits" - NFBTaxSettlementLine."Other Credits" <> 0 then
            PostGLAccount(NFBTaxSettlementHeader, GenJournalTemplate, GenJournalBatch, NFBTaxSettlementLine."Adjustment Account",
                NFBTaxSettlementLine."Other Debits" - NFBTaxSettlementLine."Other Credits", GLDescription, GenJnlPostLine);
        if NFBTaxSettlementLine.CreditsUsed() <> 0 then
            PostGLAccount(NFBTaxSettlementHeader, GenJournalTemplate, GenJournalBatch, NFBTaxPostingSetup."Recoverable Account", -NFBTaxSettlementLine.CreditsUsed(), GLDescription, GenJnlPostLine);

        if NFBTaxSettlementLine."Amount Payable" <= 0 then
            exit;
        ExternalDocumentNo := CopyStr(StrSubstNo(ExtDocNoTxt, NFBTaxSettlementHeader."No.", Format(NFBTaxSettlementLine."Tax Type".AsInteger()), NFBTaxSettlementLine."State Code"), 1, MaxStrLen(ExternalDocumentNo));
        InitJournalLine(NFBTaxSettlementHeader, GenJournalTemplate, GenJournalBatch, GenJournalLine);
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Vendor;
        GenJournalLine.Validate("Account No.", NFBTaxSettlementLine."Vendor No.");
        GenJournalLine.Validate("Currency Code", '');
        GenJournalLine.Description := CopyStr(Squeeze(StrSubstNo(VendorDescriptionTxt, NFBTaxSettlementLine."Guide Type", NFBTaxSettlementLine."Tax Type",
            NFBTaxSettlementLine."Revenue Code", Format(NFBTaxSettlementHeader."Starting Date", 0, '<Month,2>/<Year4>'))), 1, MaxStrLen(GenJournalLine.Description));
        GenJournalLine."External Document No." := ExternalDocumentNo;
        GenJournalLine.Validate(Amount, -NFBTaxSettlementLine."Amount Payable");
        GenJournalLine."Due Date" := NFBTaxSettlementLine."Due Date";
        GenJnlPostLine.RunWithCheck(GenJournalLine);

        VendorLedgerEntry.SetRange("Vendor No.", NFBTaxSettlementLine."Vendor No.");
        VendorLedgerEntry.SetRange("Document No.", NFBTaxSettlementHeader."No.");
        VendorLedgerEntry.SetRange("External Document No.", ExternalDocumentNo);
        if VendorLedgerEntry.FindLast() then
            NFBTaxSettlementLine."Vendor Ledger Entry No." := VendorLedgerEntry."Entry No.";
    end;

    local procedure PostGLAccount(NFBTaxSettlementHeader: Record "NFB Tax Settlement Header"; GenJournalTemplate: Record "Gen. Journal Template"; GenJournalBatch: Record "Gen. Journal Batch"; GLAccountNo: Code[20]; Amount: Decimal; GLDescription: Text[100]; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        InitJournalLine(NFBTaxSettlementHeader, GenJournalTemplate, GenJournalBatch, GenJournalLine);
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::"G/L Account";
        GenJournalLine.Validate("Account No.", GLAccountNo);
        // Tax accounts carry no VAT: the settlement only moves balances.
        GenJournalLine."Gen. Posting Type" := GenJournalLine."Gen. Posting Type"::" ";
        GenJournalLine."Gen. Bus. Posting Group" := '';
        GenJournalLine."Gen. Prod. Posting Group" := '';
        GenJournalLine."VAT Bus. Posting Group" := '';
        GenJournalLine."VAT Prod. Posting Group" := '';
        GenJournalLine."VAT Calculation Type" := GenJournalLine."VAT Calculation Type"::"Normal VAT";
        GenJournalLine."VAT %" := 0;
        GenJournalLine.Description := GLDescription;
        GenJournalLine.Validate(Amount, Amount);
        GenJnlPostLine.RunWithCheck(GenJournalLine);
    end;

    local procedure InitJournalLine(NFBTaxSettlementHeader: Record "NFB Tax Settlement Header"; GenJournalTemplate: Record "Gen. Journal Template"; GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Source Code" := GenJournalTemplate."Source Code";
        GenJournalLine."Reason Code" := GenJournalBatch."Reason Code";
        GenJournalLine."Posting Date" := NFBTaxSettlementHeader."Posting Date";
        GenJournalLine."Document Date" := NFBTaxSettlementHeader."Posting Date";
        GenJournalLine."Document No." := NFBTaxSettlementHeader."No.";
        // Same (blank) document type on every line keeps the whole settlement in one balanced transaction.
        // A blank type also skips the purchase invoice number check, which would reject the second guide
        // of the settlement (same Document No.) and a new posting after Reopen.
        // System-created lines may post to tax accounts without direct posting.
        GenJournalLine."Document Type" := GenJournalLine."Document Type"::" ";
        GenJournalLine."System-Created Entry" := true;
    end;

    local procedure Squeeze(Value: Text): Text
    begin
        while StrPos(Value, '  ') > 0 do
            Value := DelStr(Value, StrPos(Value, '  '), 1);
        exit(DelChr(Value, '<>', ' '));
    end;

    local procedure FindRegisterNo(GLEntryNo: Integer): Integer
    var
        GLRegister: Record "G/L Register";
    begin
        GLRegister.SetFilter("From Entry No.", '<=%1', GLEntryNo);
        GLRegister.SetFilter("To Entry No.", '>=%1', GLEntryNo);
        if GLRegister.FindFirst() then
            exit(GLRegister."No.");
    end;
}
