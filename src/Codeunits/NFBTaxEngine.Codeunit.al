codeunit 50112 "NFB Tax Engine"
{
    var
        NFBSetup: Record "NFB Setup";
        NoTaxRuleErr: Label 'No NF-e tax rule matches line %1 (operation %2, tax group %3, destination %4).', Comment = '%1 = line no., %2 = operation type, %3 = tax group, %4 = destination';

    procedure CalculateSalesDocument(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        TempCalcLine: Record "NFB Document Line" temporary;
        NFBTaxRule: Record "NFB Tax Rule";
        NFBTaxLine: Record "NFB Tax Line";
        NFBOperationMgt: Codeunit "NFB Operation Mgt";
        DestinationId: Enum "NFB Destination Id";
        IEIndicator: Enum "NFB IE Indicator";
        RecipientUF: Code[2];
        Factor: Decimal;
    begin
        if SalesHeader."NFB Operation Type" = '' then
            exit;
        NFBTaxLine.DeleteForDocument(Database::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.");

        Customer.Get(SalesHeader."Bill-to Customer No.");
        IEIndicator := Customer."NFB IE Indicator";
        RecipientUF := GetSalesRecipientUF(SalesHeader, Customer);
        DestinationId := NFBOperationMgt.GetDestinationId(
            NFBOperationMgt.GetIssuerUF(SalesHeader."Location Code"), RecipientUF, SalesHeader."Ship-to Country/Region Code");

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("NFB System Line", false);
        SalesLine.SetFilter(Type, '<>%1', SalesLine.Type::" ");
        if SalesLine.FindSet(true) then
            repeat
                if SalesLine.Quantity <> 0 then begin
                    Factor := SalesLine."Qty. to Invoice" / SalesLine.Quantity;
                    InitCalcLine(TempCalcLine, SalesLine."No.", SalesLine.Type = SalesLine.Type::Item,
                        SalesLine."Unit Price" * SalesLine."Qty. to Invoice",
                        (SalesLine."Line Discount Amount" + SalesLine."Inv. Discount Amount") * Factor);
                    FindRuleOrError(NFBTaxRule, SalesHeader."NFB Operation Type", GetItemTaxGroup(SalesLine.Type = SalesLine.Type::Item, SalesLine."No."),
                        DestinationId, IEIndicator, SalesHeader."NFB Final Consumer", RecipientUF, SalesLine."Line No.");
                    CalculateLine(TempCalcLine, NFBTaxRule, SalesHeader."NFB Final Consumer", DestinationId, IEIndicator);
                    WriteTaxLines(Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", TempCalcLine, NFBTaxRule.Code);
                    UpdateLineCfop(SalesLine."NFB CFOP", SalesLine."NFB Tax Rule Code", NFBTaxRule, SalesHeader."NFB Operation Type", DestinationId);
                    SalesLine.Modify();
                end;
            until SalesLine.Next() = 0;
    end;

    procedure CalculatePurchaseDocument(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        TempCalcLine: Record "NFB Document Line" temporary;
        NFBTaxRule: Record "NFB Tax Rule";
        NFBTaxLine: Record "NFB Tax Line";
        NFBImportDeclaration: Record "NFB Import Declaration";
        NFBOperationMgt: Codeunit "NFB Operation Mgt";
        DestinationId: Enum "NFB Destination Id";
        IEIndicator: Enum "NFB IE Indicator";
        Factor: Decimal;
    begin
        if PurchaseHeader."NFB Operation Type" = '' then
            exit;
        NFBTaxLine.DeleteForDocument(Database::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.");

        Vendor.Get(PurchaseHeader."Pay-to Vendor No.");
        IEIndicator := Vendor."NFB IE Indicator";
        DestinationId := NFBOperationMgt.GetDestinationId(
            NFBOperationMgt.GetIssuerUF(PurchaseHeader."Location Code"), Vendor."NFB UF", PurchaseHeader."Buy-from Country/Region Code");

        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("NFB System Line", false);
        PurchaseLine.SetFilter(Type, '<>%1', PurchaseLine.Type::" ");
        if PurchaseLine.FindSet(true) then
            repeat
                if PurchaseLine.Quantity <> 0 then begin
                    Factor := PurchaseLine."Qty. to Invoice" / PurchaseLine.Quantity;
                    InitCalcLine(TempCalcLine, PurchaseLine."No.", PurchaseLine.Type = PurchaseLine.Type::Item,
                        PurchaseLine."Direct Unit Cost" * PurchaseLine."Qty. to Invoice",
                        (PurchaseLine."Line Discount Amount" + PurchaseLine."Inv. Discount Amount") * Factor);
                    if NFBImportDeclaration.Get(Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.") then begin
                        TempCalcLine."II Amount" := NFBImportDeclaration."II Amount";
                        TempCalcLine."II Customs Expenses" := NFBImportDeclaration."Customs Expenses";
                        TempCalcLine."Other Expenses" := NFBImportDeclaration."Customs Expenses" + NFBImportDeclaration."AFRMM Amount";
                    end;
                    FindRuleOrError(NFBTaxRule, PurchaseHeader."NFB Operation Type", GetItemTaxGroup(PurchaseLine.Type = PurchaseLine.Type::Item, PurchaseLine."No."),
                        DestinationId, IEIndicator, false, Vendor."NFB UF", PurchaseLine."Line No.");
                    CalculateLine(TempCalcLine, NFBTaxRule, false, DestinationId, IEIndicator);
                    WriteTaxLines(Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.", TempCalcLine, NFBTaxRule.Code);
                    UpdateLineCfop(PurchaseLine."NFB CFOP", PurchaseLine."NFB Tax Rule Code", NFBTaxRule, PurchaseHeader."NFB Operation Type", DestinationId);
                    PurchaseLine.Modify();
                end;
            until PurchaseLine.Next() = 0;
    end;

    procedure CalculateTransferShipmentLine(TransferShipmentHeader: Record "Transfer Shipment Header"; TransferShipmentLine: Record "Transfer Shipment Line"; DestinationId: Enum "NFB Destination Id"; RecipientUF: Code[2]; var TempCalcLine: Record "NFB Document Line" temporary; var NFBTaxRule: Record "NFB Tax Rule")
    var
        Item: Record Item;
    begin
        // Transfers carry no price: the item unit cost is used as the operation value.
        Item.Get(TransferShipmentLine."Item No.");
        InitCalcLine(TempCalcLine, TransferShipmentLine."Item No.", true,
            Round(Item."Unit Cost" * TransferShipmentLine."Quantity (Base)", 0.01), 0);
        FindRuleOrError(NFBTaxRule, TransferShipmentHeader."NFB Operation Type", Item."NFB Tax Group",
            DestinationId, Enum::"NFB IE Indicator"::Contributor, false, RecipientUF, TransferShipmentLine."Line No.");
        CalculateLine(TempCalcLine, NFBTaxRule, false, DestinationId, Enum::"NFB IE Indicator"::Contributor);
    end;

    procedure InitCalcLine(var TempCalcLine: Record "NFB Document Line" temporary; No: Code[20]; IsItem: Boolean; GrossAmount: Decimal; DiscountAmount: Decimal)
    var
        Item: Record Item;
    begin
        Clear(TempCalcLine);
        TempCalcLine."Product Code" := No;
        TempCalcLine."Products Amount" := Round(GrossAmount, 0.01);
        TempCalcLine."Discount Amount" := Round(DiscountAmount, 0.01);
        if IsItem and Item.Get(No) then begin
            TempCalcLine.NCM := Item."NFB NCM";
            TempCalcLine.Origin := Item."NFB Origin";
            TempCalcLine.cClassTrib := Item."NFB cClassTrib";
        end;
    end;

    procedure FindRule(var NFBTaxRule: Record "NFB Tax Rule"; OperationType: Code[20]; TaxGroup: Code[20]; DestinationId: Enum "NFB Destination Id"; IEIndicator: Enum "NFB IE Indicator"; FinalConsumer: Boolean; DestinationUF: Code[2]): Boolean
    var
        Candidate: Record "NFB Tax Rule";
        BestScore: Integer;
        Found: Boolean;
    begin
        BestScore := -1;
        Candidate.SetFilter("Operation Type", '%1|%2', '', OperationType);
        Candidate.SetFilter("Tax Group", '%1|%2', '', TaxGroup);
        Candidate.SetFilter("Destination UF", '%1|%2', '', DestinationUF);
        Candidate.SetFilter(Destination, '%1|%2', Candidate.Destination::" ", DestinationId.AsInteger());
        if Candidate.FindSet() then
            repeat
                if MatchesIE(Candidate, IEIndicator) and MatchesFinalConsumer(Candidate, FinalConsumer) then
                    if Candidate.Specificity() > BestScore then begin
                        NFBTaxRule := Candidate;
                        BestScore := Candidate.Specificity();
                        Found := true;
                    end;
            until Candidate.Next() = 0;
        exit(Found);
    end;

    /// <summary>
    /// Calculates every tax of one item. Inputs on TempCalcLine: Products Amount, Discount Amount, Freight/Insurance/Other Expenses,
    /// II Amount, NCM and cClassTrib. Results are written to the tax fields of TempCalcLine.
    /// </summary>
    procedure CalculateLine(var TempCalcLine: Record "NFB Document Line" temporary; NFBTaxRule: Record "NFB Tax Rule"; FinalConsumer: Boolean; DestinationId: Enum "NFB Destination Id"; IEIndicator: Enum "NFB IE Indicator")
    var
        NFBNCM: Record "NFB NCM";
        NFBcClassTrib: Record "NFB cClassTrib";
        OperationBase: Decimal;
        IcmsBase: Decimal;
        StBase: Decimal;
        PisCofinsBase: Decimal;
        IbsCbsBase: Decimal;
        IpiRate: Decimal;
    begin
        NFBSetup.GetRecordOnce();
        ClearTaxFields(TempCalcLine);

        OperationBase := TempCalcLine."Products Amount" - TempCalcLine."Discount Amount" + TempCalcLine."Freight Amount" +
                         TempCalcLine."Insurance Amount" + TempCalcLine."Other Expenses" + TempCalcLine."II Amount";

        // IPI
        TempCalcLine."IPI CST" := NFBTaxRule."IPI CST";
        TempCalcLine."IPI Enq. Code" := NFBTaxRule."IPI Enq. Code";
        if IsIpiTaxed(NFBTaxRule."IPI CST") then begin
            IpiRate := NFBTaxRule."IPI %";
            if NFBTaxRule."Use NCM IPI %" and NFBNCM.Get(TempCalcLine.NCM) then
                IpiRate := NFBNCM."IPI %";
            TempCalcLine."IPI Base" := OperationBase;
            TempCalcLine."IPI %" := IpiRate;
            TempCalcLine."IPI Amount" := RoundAmount(OperationBase * IpiRate / 100);
        end;

        // ICMS and FCP (IPI enters the ICMS base when the buyer is the final consumer)
        TempCalcLine."ICMS CST" := NFBTaxRule."ICMS CST";
        if IsIcmsTaxed(NFBTaxRule."ICMS CST") then begin
            IcmsBase := OperationBase;
            if FinalConsumer then
                IcmsBase += TempCalcLine."IPI Amount";
            IcmsBase := RoundAmount(IcmsBase * (1 - NFBTaxRule."ICMS Base Reduction %" / 100));
            TempCalcLine."ICMS Base Reduction %" := NFBTaxRule."ICMS Base Reduction %";
            TempCalcLine."ICMS Base" := IcmsBase;
            TempCalcLine."ICMS %" := NFBTaxRule."ICMS %";
            TempCalcLine."ICMS Amount" := RoundAmount(IcmsBase * NFBTaxRule."ICMS %" / 100);
            if NFBTaxRule."FCP %" <> 0 then begin
                TempCalcLine."FCP Base" := IcmsBase;
                TempCalcLine."FCP %" := NFBTaxRule."FCP %";
                TempCalcLine."FCP Amount" := RoundAmount(IcmsBase * NFBTaxRule."FCP %" / 100);
            end;
        end;

        // ICMS ST and FCP ST
        if HasIcmsSt(NFBTaxRule."ICMS CST") and (NFBTaxRule."ICMS ST Internal %" <> 0) then begin
            StBase := (OperationBase + TempCalcLine."IPI Amount") * (1 + NFBTaxRule."ICMS ST MVA %" / 100);
            StBase := RoundAmount(StBase * (1 - NFBTaxRule."ICMS ST Base Reduction %" / 100));
            TempCalcLine."ICMS ST MVA %" := NFBTaxRule."ICMS ST MVA %";
            TempCalcLine."ICMS ST Base Reduction %" := NFBTaxRule."ICMS ST Base Reduction %";
            TempCalcLine."ICMS ST Base" := StBase;
            TempCalcLine."ICMS ST %" := NFBTaxRule."ICMS ST Internal %";
            TempCalcLine."ICMS ST Amount" := NonNegative(RoundAmount(StBase * NFBTaxRule."ICMS ST Internal %" / 100) - TempCalcLine."ICMS Amount");
            if NFBTaxRule."FCP ST %" <> 0 then begin
                TempCalcLine."FCP ST Base" := StBase;
                TempCalcLine."FCP ST %" := NFBTaxRule."FCP ST %";
                TempCalcLine."FCP ST Amount" := NonNegative(RoundAmount(StBase * NFBTaxRule."FCP ST %" / 100) - TempCalcLine."FCP Amount");
            end;
        end;

        // DIFAL (EC 87/2015): interstate sale to a non-contributor final consumer, single base
        if (DestinationId = DestinationId::Interstate) and FinalConsumer and
           (IEIndicator = IEIndicator::"Non-Contributor") and (NFBTaxRule."DIFAL Internal Dest. %" <> 0)
        then begin
            TempCalcLine."DIFAL Base" := RoundAmount(OperationBase + TempCalcLine."IPI Amount");
            TempCalcLine."DIFAL Internal %" := NFBTaxRule."DIFAL Internal Dest. %";
            TempCalcLine."DIFAL Interstate %" := NFBTaxRule."ICMS %";
            TempCalcLine."DIFAL Dest. Amount" := NonNegative(RoundAmount(TempCalcLine."DIFAL Base" * (NFBTaxRule."DIFAL Internal Dest. %" - NFBTaxRule."ICMS %") / 100));
            TempCalcLine."FCP Dest. %" := NFBTaxRule."FCP Dest. %";
            TempCalcLine."FCP Dest. Amount" := RoundAmount(TempCalcLine."DIFAL Base" * NFBTaxRule."FCP Dest. %" / 100);
        end;

        // PIS / COFINS (ICMS excluded from the base - STF Tema 69)
        PisCofinsBase := OperationBase - TempCalcLine."II Amount";
        if NFBSetup."Exclude ICMS from PIS/COFINS" then
            PisCofinsBase -= TempCalcLine."ICMS Amount";
        TempCalcLine."PIS CST" := NFBTaxRule."PIS CST";
        if IsPisCofinsTaxed(NFBTaxRule."PIS CST") then begin
            TempCalcLine."PIS Base" := PisCofinsBase;
            TempCalcLine."PIS %" := NFBTaxRule."PIS %";
            TempCalcLine."PIS Amount" := RoundAmount(PisCofinsBase * NFBTaxRule."PIS %" / 100);
        end;
        TempCalcLine."COFINS CST" := NFBTaxRule."COFINS CST";
        if IsPisCofinsTaxed(NFBTaxRule."COFINS CST") then begin
            TempCalcLine."COFINS Base" := PisCofinsBase;
            TempCalcLine."COFINS %" := NFBTaxRule."COFINS %";
            TempCalcLine."COFINS Amount" := RoundAmount(PisCofinsBase * NFBTaxRule."COFINS %" / 100);
        end;

        // IBS / CBS (LC 214/2025, NT 2025.002)
        if NFBTaxRule.cClassTrib <> '' then
            TempCalcLine.cClassTrib := NFBTaxRule.cClassTrib;
        TempCalcLine."IBS/CBS CST" := NFBTaxRule."IBS/CBS CST";
        if NFBcClassTrib.Get(TempCalcLine.cClassTrib) then begin
            if TempCalcLine."IBS/CBS CST" = '' then
                TempCalcLine."IBS/CBS CST" := NFBcClassTrib.CST;
            TempCalcLine."IBS Reduction %" := NFBcClassTrib."IBS Reduction %";
            TempCalcLine."CBS Reduction %" := NFBcClassTrib."CBS Reduction %";
        end;
        if TempCalcLine."IBS/CBS CST" <> '' then begin
            IbsCbsBase := OperationBase;
            if NFBSetup."Exclude Taxes from IBS/CBS" then
                IbsCbsBase -= TempCalcLine."ICMS Amount" + TempCalcLine."FCP Amount" + TempCalcLine."PIS Amount" + TempCalcLine."COFINS Amount" +
                              TempCalcLine."DIFAL Dest. Amount" + TempCalcLine."FCP Dest. Amount";
            TempCalcLine."IBS/CBS Base" := IbsCbsBase;
            TempCalcLine."IBS UF %" := NFBTaxRule."IBS UF %";
            TempCalcLine."IBS Mun. %" := NFBTaxRule."IBS Mun. %";
            TempCalcLine."CBS %" := NFBTaxRule."CBS %";
            TempCalcLine."IBS UF Amount" := RoundAmount(IbsCbsBase * NFBTaxRule."IBS UF %" * (1 - TempCalcLine."IBS Reduction %" / 100) / 100);
            TempCalcLine."IBS Mun. Amount" := RoundAmount(IbsCbsBase * NFBTaxRule."IBS Mun. %" * (1 - TempCalcLine."IBS Reduction %" / 100) / 100);
            TempCalcLine."CBS Amount" := RoundAmount(IbsCbsBase * NFBTaxRule."CBS %" * (1 - TempCalcLine."CBS Reduction %" / 100) / 100);
        end;
    end;

    procedure WriteTaxLines(TableID: Integer; DocType: Integer; DocNo: Code[20]; LineNo: Integer; TempCalcLine: Record "NFB Document Line" temporary; RuleCode: Code[20])
    var
        TaxType: Enum "NFB Tax Type";
    begin
        InsertTaxLine(TableID, DocType, DocNo, LineNo, TaxType::ICMS, TempCalcLine."ICMS CST", TempCalcLine."ICMS Base", TempCalcLine."ICMS %", TempCalcLine."ICMS Base Reduction %", 0, 0, TempCalcLine."ICMS Amount", '', RuleCode, true);
        InsertTaxLine(TableID, DocType, DocNo, LineNo, TaxType::FCP, '', TempCalcLine."FCP Base", TempCalcLine."FCP %", 0, 0, 0, TempCalcLine."FCP Amount", '', RuleCode, false);
        InsertTaxLine(TableID, DocType, DocNo, LineNo, TaxType::"ICMS ST", TempCalcLine."ICMS CST", TempCalcLine."ICMS ST Base", TempCalcLine."ICMS ST %", TempCalcLine."ICMS ST Base Reduction %", TempCalcLine."ICMS ST MVA %", 0, TempCalcLine."ICMS ST Amount", '', RuleCode, false);
        InsertTaxLine(TableID, DocType, DocNo, LineNo, TaxType::"FCP ST", '', TempCalcLine."FCP ST Base", TempCalcLine."FCP ST %", 0, 0, 0, TempCalcLine."FCP ST Amount", '', RuleCode, false);
        InsertTaxLine(TableID, DocType, DocNo, LineNo, TaxType::DIFAL, '', TempCalcLine."DIFAL Base", TempCalcLine."DIFAL Internal %", 0, 0, TempCalcLine."DIFAL Interstate %", TempCalcLine."DIFAL Dest. Amount", '', RuleCode, false);
        InsertTaxLine(TableID, DocType, DocNo, LineNo, TaxType::"FCP Dest.", '', TempCalcLine."DIFAL Base", TempCalcLine."FCP Dest. %", 0, 0, 0, TempCalcLine."FCP Dest. Amount", '', RuleCode, false);
        InsertTaxLine(TableID, DocType, DocNo, LineNo, TaxType::IPI, TempCalcLine."IPI CST", TempCalcLine."IPI Base", TempCalcLine."IPI %", 0, 0, 0, TempCalcLine."IPI Amount", TempCalcLine."IPI Enq. Code", RuleCode, TempCalcLine."IPI CST" <> '');
        InsertTaxLine(TableID, DocType, DocNo, LineNo, TaxType::PIS, TempCalcLine."PIS CST", TempCalcLine."PIS Base", TempCalcLine."PIS %", 0, 0, 0, TempCalcLine."PIS Amount", '', RuleCode, true);
        InsertTaxLine(TableID, DocType, DocNo, LineNo, TaxType::COFINS, TempCalcLine."COFINS CST", TempCalcLine."COFINS Base", TempCalcLine."COFINS %", 0, 0, 0, TempCalcLine."COFINS Amount", '', RuleCode, true);
        InsertTaxLine(TableID, DocType, DocNo, LineNo, TaxType::"IBS UF", TempCalcLine."IBS/CBS CST", TempCalcLine."IBS/CBS Base", TempCalcLine."IBS UF %", TempCalcLine."IBS Reduction %", 0, 0, TempCalcLine."IBS UF Amount", TempCalcLine.cClassTrib, RuleCode, TempCalcLine."IBS/CBS CST" <> '');
        InsertTaxLine(TableID, DocType, DocNo, LineNo, TaxType::"IBS Mun.", TempCalcLine."IBS/CBS CST", TempCalcLine."IBS/CBS Base", TempCalcLine."IBS Mun. %", TempCalcLine."IBS Reduction %", 0, 0, TempCalcLine."IBS Mun. Amount", TempCalcLine.cClassTrib, RuleCode, TempCalcLine."IBS/CBS CST" <> '');
        InsertTaxLine(TableID, DocType, DocNo, LineNo, TaxType::CBS, TempCalcLine."IBS/CBS CST", TempCalcLine."IBS/CBS Base", TempCalcLine."CBS %", TempCalcLine."CBS Reduction %", 0, 0, TempCalcLine."CBS Amount", TempCalcLine.cClassTrib, RuleCode, TempCalcLine."IBS/CBS CST" <> '');
        InsertTaxLine(TableID, DocType, DocNo, LineNo, TaxType::II, '', TempCalcLine."II Base", 0, 0, 0, 0, TempCalcLine."II Amount", '', RuleCode, false);
    end;

    /// <summary>Copies the stored tax lines of a source line into the tax fields of an NF-e line.</summary>
    procedure ApplyTaxLines(var NFBDocumentLine: Record "NFB Document Line"; TableID: Integer; DocType: Integer; DocNo: Code[20]; LineNo: Integer)
    var
        NFBTaxLine: Record "NFB Tax Line";
    begin
        NFBTaxLine.SetRange("Table ID", TableID);
        NFBTaxLine.SetRange("Document Type", DocType);
        NFBTaxLine.SetRange("Document No.", DocNo);
        NFBTaxLine.SetRange("Line No.", LineNo);
        if NFBTaxLine.FindSet() then
            repeat
                case NFBTaxLine."Tax Type" of
                    NFBTaxLine."Tax Type"::ICMS:
                        begin
                            NFBDocumentLine."ICMS CST" := NFBTaxLine.CST;
                            NFBDocumentLine."ICMS Base" := NFBTaxLine."Base Amount";
                            NFBDocumentLine."ICMS %" := NFBTaxLine."Rate %";
                            NFBDocumentLine."ICMS Base Reduction %" := NFBTaxLine."Base Reduction %";
                            NFBDocumentLine."ICMS Amount" := NFBTaxLine.Amount;
                        end;
                    NFBTaxLine."Tax Type"::FCP:
                        begin
                            NFBDocumentLine."FCP Base" := NFBTaxLine."Base Amount";
                            NFBDocumentLine."FCP %" := NFBTaxLine."Rate %";
                            NFBDocumentLine."FCP Amount" := NFBTaxLine.Amount;
                        end;
                    NFBTaxLine."Tax Type"::"ICMS ST":
                        begin
                            NFBDocumentLine."ICMS ST Base" := NFBTaxLine."Base Amount";
                            NFBDocumentLine."ICMS ST %" := NFBTaxLine."Rate %";
                            NFBDocumentLine."ICMS ST MVA %" := NFBTaxLine."MVA %";
                            NFBDocumentLine."ICMS ST Base Reduction %" := NFBTaxLine."Base Reduction %";
                            NFBDocumentLine."ICMS ST Amount" := NFBTaxLine.Amount;
                        end;
                    NFBTaxLine."Tax Type"::"FCP ST":
                        begin
                            NFBDocumentLine."FCP ST Base" := NFBTaxLine."Base Amount";
                            NFBDocumentLine."FCP ST %" := NFBTaxLine."Rate %";
                            NFBDocumentLine."FCP ST Amount" := NFBTaxLine.Amount;
                        end;
                    NFBTaxLine."Tax Type"::DIFAL:
                        begin
                            NFBDocumentLine."DIFAL Base" := NFBTaxLine."Base Amount";
                            NFBDocumentLine."DIFAL Internal %" := NFBTaxLine."Rate %";
                            NFBDocumentLine."DIFAL Interstate %" := NFBTaxLine."Secondary Rate %";
                            NFBDocumentLine."DIFAL Dest. Amount" := NFBTaxLine.Amount;
                        end;
                    NFBTaxLine."Tax Type"::"FCP Dest.":
                        begin
                            NFBDocumentLine."FCP Dest. %" := NFBTaxLine."Rate %";
                            NFBDocumentLine."FCP Dest. Amount" := NFBTaxLine.Amount;
                        end;
                    NFBTaxLine."Tax Type"::IPI:
                        begin
                            NFBDocumentLine."IPI CST" := CopyStr(NFBTaxLine.CST, 1, MaxStrLen(NFBDocumentLine."IPI CST"));
                            NFBDocumentLine."IPI Enq. Code" := CopyStr(NFBTaxLine."Classification Code", 1, MaxStrLen(NFBDocumentLine."IPI Enq. Code"));
                            NFBDocumentLine."IPI Base" := NFBTaxLine."Base Amount";
                            NFBDocumentLine."IPI %" := NFBTaxLine."Rate %";
                            NFBDocumentLine."IPI Amount" := NFBTaxLine.Amount;
                        end;
                    NFBTaxLine."Tax Type"::PIS:
                        begin
                            NFBDocumentLine."PIS CST" := CopyStr(NFBTaxLine.CST, 1, MaxStrLen(NFBDocumentLine."PIS CST"));
                            NFBDocumentLine."PIS Base" := NFBTaxLine."Base Amount";
                            NFBDocumentLine."PIS %" := NFBTaxLine."Rate %";
                            NFBDocumentLine."PIS Amount" := NFBTaxLine.Amount;
                        end;
                    NFBTaxLine."Tax Type"::COFINS:
                        begin
                            NFBDocumentLine."COFINS CST" := CopyStr(NFBTaxLine.CST, 1, MaxStrLen(NFBDocumentLine."COFINS CST"));
                            NFBDocumentLine."COFINS Base" := NFBTaxLine."Base Amount";
                            NFBDocumentLine."COFINS %" := NFBTaxLine."Rate %";
                            NFBDocumentLine."COFINS Amount" := NFBTaxLine.Amount;
                        end;
                    NFBTaxLine."Tax Type"::"IBS UF":
                        begin
                            NFBDocumentLine."IBS/CBS CST" := NFBTaxLine.CST;
                            NFBDocumentLine.cClassTrib := NFBTaxLine."Classification Code";
                            NFBDocumentLine."IBS/CBS Base" := NFBTaxLine."Base Amount";
                            NFBDocumentLine."IBS UF %" := NFBTaxLine."Rate %";
                            NFBDocumentLine."IBS Reduction %" := NFBTaxLine."Base Reduction %";
                            NFBDocumentLine."IBS UF Amount" := NFBTaxLine.Amount;
                        end;
                    NFBTaxLine."Tax Type"::"IBS Mun.":
                        begin
                            NFBDocumentLine."IBS Mun. %" := NFBTaxLine."Rate %";
                            NFBDocumentLine."IBS Mun. Amount" := NFBTaxLine.Amount;
                        end;
                    NFBTaxLine."Tax Type"::CBS:
                        begin
                            NFBDocumentLine."CBS %" := NFBTaxLine."Rate %";
                            NFBDocumentLine."CBS Reduction %" := NFBTaxLine."Base Reduction %";
                            NFBDocumentLine."CBS Amount" := NFBTaxLine.Amount;
                        end;
                    NFBTaxLine."Tax Type"::II:
                        begin
                            NFBDocumentLine."II Base" := NFBTaxLine."Base Amount";
                            NFBDocumentLine."II Amount" := NFBTaxLine.Amount;
                        end;
                end;
            until NFBTaxLine.Next() = 0;
    end;

    procedure IsIcmsTaxed(Cst: Code[3]): Boolean
    begin
        exit(Cst in ['00', '10', '20', '51', '70', '90']);
    end;

    procedure HasIcmsSt(Cst: Code[3]): Boolean
    begin
        exit(Cst in ['10', '30', '70', '90']);
    end;

    procedure IsIpiTaxed(Cst: Code[2]): Boolean
    begin
        exit(Cst in ['00', '49', '50', '99']);
    end;

    procedure IsPisCofinsTaxed(Cst: Code[2]): Boolean
    begin
        exit(Cst in ['01', '02', '50', '51', '52', '53', '54', '55', '56', '60', '61', '62', '63', '64', '65', '66', '99']);
    end;

    local procedure InsertTaxLine(TableID: Integer; DocType: Integer; DocNo: Code[20]; LineNo: Integer; TaxType: Enum "NFB Tax Type"; Cst: Code[3]; BaseAmount: Decimal; Rate: Decimal; Reduction: Decimal; Mva: Decimal; SecondaryRate: Decimal; TaxAmount: Decimal; ClassificationCode: Code[6]; RuleCode: Code[20]; AlwaysInsert: Boolean)
    var
        NFBTaxLine: Record "NFB Tax Line";
    begin
        if (TaxAmount = 0) and not AlwaysInsert then
            exit;
        NFBTaxLine."Table ID" := TableID;
        NFBTaxLine."Document Type" := DocType;
        NFBTaxLine."Document No." := DocNo;
        NFBTaxLine."Line No." := LineNo;
        NFBTaxLine."Tax Type" := TaxType;
        NFBTaxLine.CST := Cst;
        NFBTaxLine."Base Amount" := BaseAmount;
        NFBTaxLine."Rate %" := Rate;
        NFBTaxLine."Base Reduction %" := Reduction;
        NFBTaxLine."MVA %" := Mva;
        NFBTaxLine."Secondary Rate %" := SecondaryRate;
        NFBTaxLine.Amount := TaxAmount;
        NFBTaxLine."Classification Code" := ClassificationCode;
        NFBTaxLine."Tax Rule Code" := RuleCode;
        if not NFBTaxLine.Insert() then
            NFBTaxLine.Modify();
    end;

    local procedure ClearTaxFields(var TempCalcLine: Record "NFB Document Line" temporary)
    var
        TempBlank: Record "NFB Document Line" temporary;
    begin
        // Keep the inputs, reset everything the calculation writes.
        TempBlank."Product Code" := TempCalcLine."Product Code";
        TempBlank.NCM := TempCalcLine.NCM;
        TempBlank.Origin := TempCalcLine.Origin;
        TempBlank.cClassTrib := TempCalcLine.cClassTrib;
        TempBlank."Products Amount" := TempCalcLine."Products Amount";
        TempBlank."Discount Amount" := TempCalcLine."Discount Amount";
        TempBlank."Freight Amount" := TempCalcLine."Freight Amount";
        TempBlank."Insurance Amount" := TempCalcLine."Insurance Amount";
        TempBlank."Other Expenses" := TempCalcLine."Other Expenses";
        TempBlank."II Amount" := TempCalcLine."II Amount";
        TempBlank."II Base" := TempCalcLine."II Base";
        TempBlank."II Customs Expenses" := TempCalcLine."II Customs Expenses";
        TempCalcLine := TempBlank;
    end;

    local procedure FindRuleOrError(var NFBTaxRule: Record "NFB Tax Rule"; OperationType: Code[20]; TaxGroup: Code[20]; DestinationId: Enum "NFB Destination Id"; IEIndicator: Enum "NFB IE Indicator"; FinalConsumer: Boolean; DestinationUF: Code[2]; LineNo: Integer)
    begin
        if not FindRule(NFBTaxRule, OperationType, TaxGroup, DestinationId, IEIndicator, FinalConsumer, DestinationUF) then
            Error(NoTaxRuleErr, LineNo, OperationType, TaxGroup, DestinationId);
    end;

    local procedure UpdateLineCfop(var LineCfop: Code[4]; var LineRuleCode: Code[20]; NFBTaxRule: Record "NFB Tax Rule"; OperationType: Code[20]; DestinationId: Enum "NFB Destination Id")
    var
        NFBOperationType: Record "NFB Operation Type";
    begin
        LineRuleCode := NFBTaxRule.Code;
        if LineCfop <> '' then
            exit;
        if NFBTaxRule.CFOP <> '' then
            LineCfop := NFBTaxRule.CFOP
        else
            if NFBOperationType.Get(OperationType) then
                LineCfop := NFBOperationType.GetCFOP(DestinationId);
    end;

    local procedure GetItemTaxGroup(IsItem: Boolean; No: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        if IsItem and Item.Get(No) then
            exit(Item."NFB Tax Group");
    end;

    local procedure GetSalesRecipientUF(SalesHeader: Record "Sales Header"; Customer: Record Customer): Code[2]
    var
        ShipToAddress: Record "Ship-to Address";
    begin
        if SalesHeader."Ship-to Code" <> '' then
            if ShipToAddress.Get(SalesHeader."Sell-to Customer No.", SalesHeader."Ship-to Code") then
                if ShipToAddress."NFB UF" <> '' then
                    exit(ShipToAddress."NFB UF");
        exit(Customer."NFB UF");
    end;

    local procedure MatchesIE(NFBTaxRule: Record "NFB Tax Rule"; IEIndicator: Enum "NFB IE Indicator"): Boolean
    begin
        case NFBTaxRule."IE Indicator" of
            NFBTaxRule."IE Indicator"::" ":
                exit(true);
            NFBTaxRule."IE Indicator"::Contributor:
                exit(IEIndicator = IEIndicator::Contributor);
            NFBTaxRule."IE Indicator"::Exempt:
                exit(IEIndicator = IEIndicator::Exempt);
            NFBTaxRule."IE Indicator"::"Non-Contributor":
                exit(IEIndicator = IEIndicator::"Non-Contributor");
        end;
    end;

    local procedure MatchesFinalConsumer(NFBTaxRule: Record "NFB Tax Rule"; FinalConsumer: Boolean): Boolean
    begin
        case NFBTaxRule."Final Consumer" of
            NFBTaxRule."Final Consumer"::" ":
                exit(true);
            NFBTaxRule."Final Consumer"::Yes:
                exit(FinalConsumer);
            NFBTaxRule."Final Consumer"::No:
                exit(not FinalConsumer);
        end;
    end;

    local procedure RoundAmount(Value: Decimal): Decimal
    begin
        exit(Round(Value, 0.01));
    end;

    local procedure NonNegative(Value: Decimal): Decimal
    begin
        if Value < 0 then
            exit(0);
        exit(Value);
    end;
}
