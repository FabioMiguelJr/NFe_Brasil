codeunit 50202 "NFB Tax Posting"
{
    // Business Central W1 has no Brazilian taxes. The extension posts them through G/L account lines
    // ("system lines") added to the document right before posting, so they run in the same transaction:
    // - taxes charged on top of the price (IPI, ICMS ST, FCP ST) become one line that raises the customer/vendor amount;
    // - taxes included in the price (ICMS, FCP, DIFAL, PIS, COFINS, IBS, CBS) become a pair of lines that net to zero:
    //   sales debit the deduction account and credit the payable account; purchases debit the recoverable account and credit cost.

    var
        SystemLineDescriptionTxt: Label 'NF-e %1', Comment = '%1 = tax type';

    procedure InsertSalesTaxLines(var SalesHeader: Record "Sales Header")
    var
        NFBTaxPostingSetup: Record "NFB Tax Posting Setup";
        TaxType: Enum "NFB Tax Type";
        TaxAmount: Decimal;
        Ordinal: Integer;
    begin
        DeleteOpenSalesSystemLines(SalesHeader);
        foreach Ordinal in Enum::"NFB Tax Type".Ordinals() do begin
            TaxType := Enum::"NFB Tax Type".FromInteger(Ordinal);
            TaxAmount := SumTaxAmount(Database::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.", TaxType);
            if (TaxAmount <> 0) and NFBTaxPostingSetup.Get(TaxType) then
                if NFBTaxPostingSetup."Payable Account" <> '' then
                    if NFBTaxPostingSetup.IsIncludedInPrice(TaxType) then begin
                        if NFBTaxPostingSetup."Sales Deduction Account" <> '' then begin
                            InsertSalesSystemLine(SalesHeader, TaxType, NFBTaxPostingSetup."Payable Account", 1, TaxAmount);
                            InsertSalesSystemLine(SalesHeader, TaxType, NFBTaxPostingSetup."Sales Deduction Account", -1, TaxAmount);
                        end;
                    end else
                        InsertSalesSystemLine(SalesHeader, TaxType, NFBTaxPostingSetup."Payable Account", 1, TaxAmount);
        end;
    end;

    procedure InsertPurchaseTaxLines(var PurchaseHeader: Record "Purchase Header")
    var
        NFBTaxPostingSetup: Record "NFB Tax Posting Setup";
        TaxType: Enum "NFB Tax Type";
        TaxAmount: Decimal;
        Ordinal: Integer;
        DebitAccount: Code[20];
    begin
        DeleteOpenPurchaseSystemLines(PurchaseHeader);
        foreach Ordinal in Enum::"NFB Tax Type".Ordinals() do begin
            TaxType := Enum::"NFB Tax Type".FromInteger(Ordinal);
            TaxAmount := SumTaxAmount(Database::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.", TaxType);
            if (TaxAmount <> 0) and NFBTaxPostingSetup.Get(TaxType) and (TaxType <> TaxType::II) then
                if NFBTaxPostingSetup.IsIncludedInPrice(TaxType) then begin
                    // Credit only when a recoverable account is set (e.g. ICMS); none for PIS/COFINS under Lucro Presumido.
                    if (NFBTaxPostingSetup."Recoverable Account" <> '') and (NFBTaxPostingSetup."Purchase Cost Account" <> '') then begin
                        InsertPurchaseSystemLine(PurchaseHeader, TaxType, NFBTaxPostingSetup."Recoverable Account", 1, TaxAmount);
                        InsertPurchaseSystemLine(PurchaseHeader, TaxType, NFBTaxPostingSetup."Purchase Cost Account", -1, TaxAmount);
                    end;
                end else begin
                    DebitAccount := NFBTaxPostingSetup."Recoverable Account";
                    if DebitAccount = '' then
                        DebitAccount := NFBTaxPostingSetup."Purchase Cost Account";
                    if DebitAccount <> '' then
                        InsertPurchaseSystemLine(PurchaseHeader, TaxType, DebitAccount, 1, TaxAmount);
                end;
        end;
    end;

    procedure SumTaxAmount(TableID: Integer; DocType: Integer; DocNo: Code[20]; TaxType: Enum "NFB Tax Type"): Decimal
    var
        NFBTaxLine: Record "NFB Tax Line";
    begin
        NFBTaxLine.SetRange("Table ID", TableID);
        NFBTaxLine.SetRange("Document Type", DocType);
        NFBTaxLine.SetRange("Document No.", DocNo);
        NFBTaxLine.SetRange("Tax Type", TaxType);
        NFBTaxLine.CalcSums(Amount);
        exit(NFBTaxLine.Amount);
    end;

    local procedure InsertSalesSystemLine(SalesHeader: Record "Sales Header"; TaxType: Enum "NFB Tax Type"; GLAccountNo: Code[20]; Qty: Decimal; TaxAmount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := GetNextSalesLineNo(SalesHeader);
        SalesLine."System-Created Entry" := true;
        SalesLine.Validate(Type, SalesLine.Type::"G/L Account");
        SalesLine.Validate("No.", GLAccountNo);
        SalesLine.Description := CopyStr(StrSubstNo(SystemLineDescriptionTxt, TaxType), 1, MaxStrLen(SalesLine.Description));
        SalesLine.Validate(Quantity, Qty);
        SalesLine.Validate("Unit Price", TaxAmount);
        SalesLine."Allow Invoice Disc." := false;
        SalesLine."NFB System Line" := true;
        SalesLine."NFB Tax Type" := TaxType;
        SalesLine.Insert(true);
    end;

    local procedure InsertPurchaseSystemLine(PurchaseHeader: Record "Purchase Header"; TaxType: Enum "NFB Tax Type"; GLAccountNo: Code[20]; Qty: Decimal; TaxAmount: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.Init();
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Line No." := GetNextPurchaseLineNo(PurchaseHeader);
        PurchaseLine."System-Created Entry" := true;
        PurchaseLine.Validate(Type, PurchaseLine.Type::"G/L Account");
        PurchaseLine.Validate("No.", GLAccountNo);
        PurchaseLine.Description := CopyStr(StrSubstNo(SystemLineDescriptionTxt, TaxType), 1, MaxStrLen(PurchaseLine.Description));
        PurchaseLine.Validate(Quantity, Qty);
        PurchaseLine.Validate("Direct Unit Cost", TaxAmount);
        PurchaseLine."Allow Invoice Disc." := false;
        PurchaseLine."NFB System Line" := true;
        PurchaseLine."NFB Tax Type" := TaxType;
        PurchaseLine.Insert(true);
    end;

    local procedure DeleteOpenSalesSystemLines(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("NFB System Line", true);
        SalesLine.SetRange("Quantity Invoiced", 0);
        SalesLine.DeleteAll(true);
    end;

    local procedure DeleteOpenPurchaseSystemLines(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("NFB System Line", true);
        PurchaseLine.SetRange("Quantity Invoiced", 0);
        PurchaseLine.DeleteAll(true);
    end;

    local procedure GetNextSalesLineNo(SalesHeader: Record "Sales Header"): Integer
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindLast() then
            exit(SalesLine."Line No." + 10000);
        exit(10000);
    end;

    local procedure GetNextPurchaseLineNo(PurchaseHeader: Record "Purchase Header"): Integer
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindLast() then
            exit(PurchaseLine."Line No." + 10000);
        exit(10000);
    end;
}
