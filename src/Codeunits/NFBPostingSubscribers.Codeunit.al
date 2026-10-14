codeunit 50108 "NFB Posting Subscribers"
{
    // Hooks the NF-e flow into standard posting:
    // before posting  -> validate fiscal master data, calculate taxes, add tax system lines (same transaction);
    // line insertion  -> carry tax lines and import declarations to the posted lines;
    // after posting   -> create the NF-e document (outside the posting transaction).

    var
        NFBTaxEngine: Codeunit "NFB Tax Engine";
        NFBTaxPosting: Codeunit "NFB Tax Posting";
        NFBCreateDocument: Codeunit "NFB Create Document";
        MissingMasterDataErr: Label '%1 %2 is missing NF-e data: %3.', Comment = '%1 = table caption, %2 = no., %3 = field caption';

    // Sales

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostSalesDoc', '', false, false)]
    local procedure SalesPostOnBeforePostSalesDoc(var SalesHeader: Record "Sales Header")
    var
        NFBOperationType: Record "NFB Operation Type";
    begin
        if not NFBOperationType.Get(SalesHeader."NFB Operation Type") then
            exit;
        if not (SalesHeader.Invoice or (SalesHeader."Document Type" in [SalesHeader."Document Type"::Invoice, SalesHeader."Document Type"::"Credit Memo"])) then
            exit;
        if NFBOperationType."Issue NF-e" then
            CheckSalesMasterData(SalesHeader);
        if NFBOperationType."Calculate Taxes" then
            NFBTaxEngine.CalculateSalesDocument(SalesHeader);
        if NFBOperationType."Calculate Taxes" and NFBOperationType."Post Taxes" then
            NFBTaxPosting.InsertSalesTaxLines(SalesHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterSalesInvLineInsert', '', false, false)]
    local procedure SalesPostOnAfterSalesInvLineInsert(var SalesInvLine: Record "Sales Invoice Line"; SalesLine: Record "Sales Line")
    var
        NFBTaxLine: Record "NFB Tax Line";
    begin
        NFBTaxLine.CopyToDocument(Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.",
            Database::"Sales Invoice Line", 0, SalesInvLine."Document No.", SalesInvLine."Line No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterSalesCrMemoLineInsert', '', false, false)]
    local procedure SalesPostOnAfterSalesCrMemoLineInsert(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; SalesLine: Record "Sales Line")
    var
        NFBTaxLine: Record "NFB Tax Line";
    begin
        NFBTaxLine.CopyToDocument(Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.",
            Database::"Sales Cr.Memo Line", 0, SalesCrMemoLine."Document No.", SalesCrMemoLine."Line No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure SalesPostOnAfterPostSalesDoc(var SalesHeader: Record "Sales Header"; SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20]; CommitIsSuppressed: Boolean; PreviewMode: Boolean)
    var
        SalesHeader2: Record "Sales Header";
        NFBTaxLine: Record "NFB Tax Line";
        NFBDocumentBuilder: Codeunit "NFB Document Builder";
    begin
        if PreviewMode then
            exit;
        if not SalesHeader2.Get(SalesHeader."Document Type", SalesHeader."No.") then
            NFBTaxLine.DeleteForDocument(Database::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
        if CommitIsSuppressed or not NFBDocumentBuilder.ShouldIssue(SalesHeader."NFB Operation Type") then
            exit;
        Commit();
        if SalesInvHdrNo <> '' then
            NFBCreateDocument.TryCreate("NFB Source Doc. Type"::"Sales Invoice", SalesInvHdrNo);
        if SalesCrMemoHdrNo <> '' then
            NFBCreateDocument.TryCreate("NFB Source Doc. Type"::"Sales Cr. Memo", SalesCrMemoHdrNo);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure SalesHeaderOnAfterDelete(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    var
        NFBTaxLine: Record "NFB Tax Line";
    begin
        if Rec.IsTemporary() then
            exit;
        NFBTaxLine.DeleteForDocument(Database::"Sales Line", Rec."Document Type".AsInteger(), Rec."No.");
    end;

    // Purchases

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostPurchaseDoc', '', false, false)]
    local procedure PurchPostOnBeforePostPurchaseDoc(var PurchaseHeader: Record "Purchase Header")
    var
        NFBOperationType: Record "NFB Operation Type";
    begin
        if not NFBOperationType.Get(PurchaseHeader."NFB Operation Type") then
            exit;
        if not (PurchaseHeader.Invoice or (PurchaseHeader."Document Type" in [PurchaseHeader."Document Type"::Invoice, PurchaseHeader."Document Type"::"Credit Memo"])) then
            exit;
        if NFBOperationType."Issue NF-e" then
            CheckPurchaseMasterData(PurchaseHeader);
        if NFBOperationType."Calculate Taxes" then
            NFBTaxEngine.CalculatePurchaseDocument(PurchaseHeader);
        if NFBOperationType."Calculate Taxes" and NFBOperationType."Post Taxes" then
            NFBTaxPosting.InsertPurchaseTaxLines(PurchaseHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPurchInvLineInsert', '', false, false)]
    local procedure PurchPostOnAfterPurchInvLineInsert(var PurchInvLine: Record "Purch. Inv. Line"; PurchLine: Record "Purchase Line")
    var
        NFBTaxLine: Record "NFB Tax Line";
    begin
        NFBTaxLine.CopyToDocument(Database::"Purchase Line", PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchLine."Line No.",
            Database::"Purch. Inv. Line", 0, PurchInvLine."Document No.", PurchInvLine."Line No.");
        CopyImportDeclaration(PurchLine, Database::"Purch. Inv. Line", PurchInvLine."Document No.", PurchInvLine."Line No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPurchCrMemoLineInsert', '', false, false)]
    local procedure PurchPostOnAfterPurchCrMemoLineInsert(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; var PurchLine: Record "Purchase Line")
    var
        NFBTaxLine: Record "NFB Tax Line";
    begin
        NFBTaxLine.CopyToDocument(Database::"Purchase Line", PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchLine."Line No.",
            Database::"Purch. Cr. Memo Line", 0, PurchCrMemoLine."Document No.", PurchCrMemoLine."Line No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPostPurchaseDoc', '', false, false)]
    local procedure PurchPostOnAfterPostPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PurchInvHdrNo: Code[20]; PurchCrMemoHdrNo: Code[20]; CommitIsSupressed: Boolean)
    var
        PurchaseHeader2: Record "Purchase Header";
        NFBTaxLine: Record "NFB Tax Line";
        NFBImportDeclaration: Record "NFB Import Declaration";
        NFBDocumentBuilder: Codeunit "NFB Document Builder";
    begin
        if not PurchaseHeader2.Get(PurchaseHeader."Document Type", PurchaseHeader."No.") then begin
            NFBTaxLine.DeleteForDocument(Database::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.");
            NFBImportDeclaration.SetRange("Table ID", Database::"Purchase Line");
            NFBImportDeclaration.SetRange("Document Type", PurchaseHeader."Document Type".AsInteger());
            NFBImportDeclaration.SetRange("Document No.", PurchaseHeader."No.");
            NFBImportDeclaration.DeleteAll();
        end;
        if CommitIsSupressed or not NFBDocumentBuilder.ShouldIssue(PurchaseHeader."NFB Operation Type") then
            exit;
        Commit();
        if PurchInvHdrNo <> '' then
            NFBCreateDocument.TryCreate("NFB Source Doc. Type"::"Purchase Invoice", PurchInvHdrNo);
        if PurchCrMemoHdrNo <> '' then
            NFBCreateDocument.TryCreate("NFB Source Doc. Type"::"Purchase Cr. Memo", PurchCrMemoHdrNo);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure PurchaseHeaderOnAfterDelete(var Rec: Record "Purchase Header"; RunTrigger: Boolean)
    var
        NFBTaxLine: Record "NFB Tax Line";
    begin
        if Rec.IsTemporary() then
            exit;
        NFBTaxLine.DeleteForDocument(Database::"Purchase Line", Rec."Document Type".AsInteger(), Rec."No.");
    end;

    // Transfers

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Shipment", 'OnAfterTransferOrderPostShipment', '', false, false)]
    local procedure TransferOnAfterPostShipment(var TransferHeader: Record "Transfer Header"; CommitIsSuppressed: Boolean; var TransferShipmentHeader: Record "Transfer Shipment Header")
    var
        TransferLine: Record "Transfer Line";
        TransferShipmentLine: Record "Transfer Shipment Line";
        NFBDocumentBuilder: Codeunit "NFB Document Builder";
    begin
        // Transfer Shipment Header/Line are not filled with TransferFields, so the NF-e fields are copied here.
        TransferShipmentHeader."NFB Operation Type" := TransferHeader."NFB Operation Type";
        TransferShipmentHeader."NFB Nature of Operation" := TransferHeader."NFB Nature of Operation";
        TransferShipmentHeader."NFB Purpose" := TransferHeader."NFB Purpose";
        TransferShipmentHeader."NFB Presence Indicator" := TransferHeader."NFB Presence Indicator";
        TransferShipmentHeader."NFB Freight Mode" := TransferHeader."NFB Freight Mode";
        TransferShipmentHeader."NFB Final Consumer" := TransferHeader."NFB Final Consumer";
        TransferShipmentHeader."NFB Referenced Key" := TransferHeader."NFB Referenced Key";
        TransferShipmentHeader."NFB Additional Info" := TransferHeader."NFB Additional Info";
        TransferShipmentHeader.Modify();

        TransferShipmentLine.SetRange("Document No.", TransferShipmentHeader."No.");
        if TransferShipmentLine.FindSet(true) then
            repeat
                if TransferLine.Get(TransferHeader."No.", TransferShipmentLine."Line No.") then begin
                    TransferShipmentLine."NFB CFOP" := TransferLine."NFB CFOP";
                    TransferShipmentLine."NFB Tax Rule Code" := TransferLine."NFB Tax Rule Code";
                    TransferShipmentLine.Modify();
                end;
            until TransferShipmentLine.Next() = 0;

        if CommitIsSuppressed or not NFBDocumentBuilder.ShouldIssue(TransferShipmentHeader."NFB Operation Type") then
            exit;
        Commit();
        NFBCreateDocument.TryCreate("NFB Source Doc. Type"::"Transfer Shipment", TransferShipmentHeader."No.");
    end;

    local procedure CopyImportDeclaration(PurchLine: Record "Purchase Line"; ToTableID: Integer; ToDocNo: Code[20]; ToLineNo: Integer)
    var
        FromDeclaration: Record "NFB Import Declaration";
        ToDeclaration: Record "NFB Import Declaration";
    begin
        if not FromDeclaration.Get(Database::"Purchase Line", PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchLine."Line No.") then
            exit;
        ToDeclaration := FromDeclaration;
        ToDeclaration."Table ID" := ToTableID;
        ToDeclaration."Document Type" := 0;
        ToDeclaration."Document No." := ToDocNo;
        ToDeclaration."Line No." := ToLineNo;
        if not ToDeclaration.Insert() then
            ToDeclaration.Modify();
    end;

    local procedure CheckSalesMasterData(SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        Customer.Get(SalesHeader."Bill-to Customer No.");
        if Customer."NFB Person Type" <> Customer."NFB Person Type"::Foreign then begin
            if Customer."NFB CPF/CNPJ" = '' then
                Error(MissingMasterDataErr, Customer.TableCaption(), Customer."No.", Customer.FieldCaption("NFB CPF/CNPJ"));
            if Customer."NFB Municipality Code" = '' then
                Error(MissingMasterDataErr, Customer.TableCaption(), Customer."No.", Customer.FieldCaption("NFB Municipality Code"));
        end;
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetFilter("Qty. to Invoice", '<>0');
        if SalesLine.FindSet() then
            repeat
                Item.Get(SalesLine."No.");
                if Item."NFB NCM" = '' then
                    Error(MissingMasterDataErr, Item.TableCaption(), Item."No.", Item.FieldCaption("NFB NCM"));
            until SalesLine.Next() = 0;
    end;

    local procedure CheckPurchaseMasterData(PurchaseHeader: Record "Purchase Header")
    var
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        Vendor.Get(PurchaseHeader."Pay-to Vendor No.");
        if Vendor."NFB Person Type" <> Vendor."NFB Person Type"::Foreign then
            if Vendor."NFB CPF/CNPJ" = '' then
                Error(MissingMasterDataErr, Vendor.TableCaption(), Vendor."No.", Vendor.FieldCaption("NFB CPF/CNPJ"));
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetFilter("Qty. to Invoice", '<>0');
        if PurchaseLine.FindSet() then
            repeat
                Item.Get(PurchaseLine."No.");
                if Item."NFB NCM" = '' then
                    Error(MissingMasterDataErr, Item.TableCaption(), Item."No.", Item.FieldCaption("NFB NCM"));
            until PurchaseLine.Next() = 0;
    end;
}
