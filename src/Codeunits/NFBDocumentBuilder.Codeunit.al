codeunit 50103 "NFB Document Builder"
{
    var
        NFBSetup: Record "NFB Setup";
        NFBTaxEngine: Codeunit "NFB Tax Engine";
        NFBValidation: Codeunit "NFB Validation";
        AlreadyExistsErr: Label 'NF-e %1 already exists for %2 %3.', Comment = '%1 = NF-e no., %2 = source type, %3 = source no.';
        NoIssueErr: Label 'Operation type %1 does not issue NF-e.', Comment = '%1 = operation type';
        NoOperationTypeErr: Label '%1 %2 has no NF-e operation type.', Comment = '%1 = source type, %2 = source no.';
        ForeignCityTxt: Label 'EXTERIOR', Locked = true;

    procedure CreateDocument(SourceDocType: Enum "NFB Source Doc. Type"; SourceDocNo: Code[20]): Code[20]
    var
        NFBDocumentHeader: Record "NFB Document Header";
    begin
        NFBDocumentHeader.SetRange("Source Doc. Type", SourceDocType);
        NFBDocumentHeader.SetRange("Source Doc. No.", SourceDocNo);
        NFBDocumentHeader.SetFilter(Status, '<>%1', NFBDocumentHeader.Status::Cancelled);
        if NFBDocumentHeader.FindFirst() then
            Error(AlreadyExistsErr, NFBDocumentHeader."No.", SourceDocType, SourceDocNo);

        case SourceDocType of
            SourceDocType::"Sales Invoice":
                exit(CreateFromSalesInvoice(SourceDocNo));
            SourceDocType::"Sales Cr. Memo":
                exit(CreateFromSalesCrMemo(SourceDocNo));
            SourceDocType::"Purchase Invoice":
                exit(CreateFromPurchInvoice(SourceDocNo));
            SourceDocType::"Purchase Cr. Memo":
                exit(CreateFromPurchCrMemo(SourceDocNo));
            SourceDocType::"Transfer Shipment":
                exit(CreateFromTransferShipment(SourceDocNo));
        end;
    end;

    procedure ShouldIssue(OperationType: Code[20]): Boolean
    var
        NFBOperationType: Record "NFB Operation Type";
    begin
        if not NFBOperationType.Get(OperationType) then
            exit(false);
        exit(NFBOperationType."Issue NF-e");
    end;

    local procedure CreateFromSalesInvoice(DocNo: Code[20]): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        NFBDocumentHeader: Record "NFB Document Header";
    begin
        SalesInvoiceHeader.Get(DocNo);
        InitHeader(NFBDocumentHeader, "NFB Source Doc. Type"::"Sales Invoice", DocNo, SalesInvoiceHeader."NFB Operation Type",
            SalesInvoiceHeader."Posting Date", SalesInvoiceHeader."Location Code");
        CopyHeaderFields(NFBDocumentHeader, SalesInvoiceHeader."NFB Nature of Operation", SalesInvoiceHeader."NFB Purpose",
            SalesInvoiceHeader."NFB Presence Indicator", SalesInvoiceHeader."NFB Final Consumer", SalesInvoiceHeader."NFB Additional Info");
        FillRecipientFromCustomer(NFBDocumentHeader, SalesInvoiceHeader."Bill-to Customer No.", SalesInvoiceHeader."Bill-to Name");
        SetDestination(NFBDocumentHeader, SalesInvoiceHeader."Ship-to Country/Region Code");
        NFBDocumentHeader.Insert(true);

        SalesInvoiceLine.SetRange("Document No.", DocNo);
        SalesInvoiceLine.SetRange("NFB System Line", false);
        SalesInvoiceLine.SetFilter(Type, '<>%1', SalesInvoiceLine.Type::" ");
        SalesInvoiceLine.SetFilter(Quantity, '<>0');
        if SalesInvoiceLine.FindSet() then
            repeat
                AddLine(NFBDocumentHeader, SalesInvoiceLine."Line No.", SalesInvoiceLine."No.", SalesInvoiceLine.Type = SalesInvoiceLine.Type::Item,
                    SalesInvoiceLine.Description, SalesInvoiceLine."Unit of Measure Code", SalesInvoiceLine.Quantity, SalesInvoiceLine."Quantity (Base)",
                    SalesInvoiceLine."Unit Price", SalesInvoiceLine."Line Discount Amount" + SalesInvoiceLine."Inv. Discount Amount", SalesInvoiceLine."NFB CFOP",
                    Database::"Sales Invoice Line", 0, DocNo);
            until SalesInvoiceLine.Next() = 0;

        AddReference(NFBDocumentHeader, SalesInvoiceHeader."NFB Referenced Key");
        AddTransport(NFBDocumentHeader, SalesInvoiceHeader."NFB Freight Mode", SalesInvoiceHeader."Shipping Agent Code");
        UpdateTotals(NFBDocumentHeader);
        AddPayment(NFBDocumentHeader, SalesInvoiceHeader."Payment Method Code", SalesInvoiceHeader."Due Date");
        exit(NFBDocumentHeader."No.");
    end;

    local procedure CreateFromSalesCrMemo(DocNo: Code[20]): Code[20]
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        NFBDocumentHeader: Record "NFB Document Header";
    begin
        SalesCrMemoHeader.Get(DocNo);
        InitHeader(NFBDocumentHeader, "NFB Source Doc. Type"::"Sales Cr. Memo", DocNo, SalesCrMemoHeader."NFB Operation Type",
            SalesCrMemoHeader."Posting Date", SalesCrMemoHeader."Location Code");
        CopyHeaderFields(NFBDocumentHeader, SalesCrMemoHeader."NFB Nature of Operation", SalesCrMemoHeader."NFB Purpose",
            SalesCrMemoHeader."NFB Presence Indicator", SalesCrMemoHeader."NFB Final Consumer", SalesCrMemoHeader."NFB Additional Info");
        FillRecipientFromCustomer(NFBDocumentHeader, SalesCrMemoHeader."Bill-to Customer No.", SalesCrMemoHeader."Bill-to Name");
        SetDestination(NFBDocumentHeader, SalesCrMemoHeader."Ship-to Country/Region Code");
        NFBDocumentHeader.Insert(true);

        SalesCrMemoLine.SetRange("Document No.", DocNo);
        SalesCrMemoLine.SetRange("NFB System Line", false);
        SalesCrMemoLine.SetFilter(Type, '<>%1', SalesCrMemoLine.Type::" ");
        SalesCrMemoLine.SetFilter(Quantity, '<>0');
        if SalesCrMemoLine.FindSet() then
            repeat
                AddLine(NFBDocumentHeader, SalesCrMemoLine."Line No.", SalesCrMemoLine."No.", SalesCrMemoLine.Type = SalesCrMemoLine.Type::Item,
                    SalesCrMemoLine.Description, SalesCrMemoLine."Unit of Measure Code", SalesCrMemoLine.Quantity, SalesCrMemoLine."Quantity (Base)",
                    SalesCrMemoLine."Unit Price", SalesCrMemoLine."Line Discount Amount" + SalesCrMemoLine."Inv. Discount Amount", SalesCrMemoLine."NFB CFOP",
                    Database::"Sales Cr.Memo Line", 0, DocNo);
            until SalesCrMemoLine.Next() = 0;

        AddReference(NFBDocumentHeader, SalesCrMemoHeader."NFB Referenced Key");
        if SalesCrMemoHeader."Applies-to Doc. Type" = SalesCrMemoHeader."Applies-to Doc. Type"::Invoice then
            AddReferenceFromSource(NFBDocumentHeader, "NFB Source Doc. Type"::"Sales Invoice", SalesCrMemoHeader."Applies-to Doc. No.");
        AddTransport(NFBDocumentHeader, SalesCrMemoHeader."NFB Freight Mode", SalesCrMemoHeader."Shipping Agent Code");
        UpdateTotals(NFBDocumentHeader);
        AddPayment(NFBDocumentHeader, '', 0D);
        exit(NFBDocumentHeader."No.");
    end;

    local procedure CreateFromPurchInvoice(DocNo: Code[20]): Code[20]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        NFBDocumentHeader: Record "NFB Document Header";
    begin
        PurchInvHeader.Get(DocNo);
        InitHeader(NFBDocumentHeader, "NFB Source Doc. Type"::"Purchase Invoice", DocNo, PurchInvHeader."NFB Operation Type",
            PurchInvHeader."Posting Date", PurchInvHeader."Location Code");
        CopyHeaderFields(NFBDocumentHeader, PurchInvHeader."NFB Nature of Operation", PurchInvHeader."NFB Purpose",
            PurchInvHeader."NFB Presence Indicator", false, PurchInvHeader."NFB Additional Info");
        FillRecipientFromVendor(NFBDocumentHeader, PurchInvHeader."Pay-to Vendor No.", PurchInvHeader."Pay-to Name");
        SetDestination(NFBDocumentHeader, PurchInvHeader."Buy-from Country/Region Code");
        NFBDocumentHeader.Insert(true);

        PurchInvLine.SetRange("Document No.", DocNo);
        PurchInvLine.SetRange("NFB System Line", false);
        PurchInvLine.SetFilter(Type, '<>%1', PurchInvLine.Type::" ");
        PurchInvLine.SetFilter(Quantity, '<>0');
        if PurchInvLine.FindSet() then
            repeat
                AddLine(NFBDocumentHeader, PurchInvLine."Line No.", PurchInvLine."No.", PurchInvLine.Type = PurchInvLine.Type::Item,
                    PurchInvLine.Description, PurchInvLine."Unit of Measure Code", PurchInvLine.Quantity, PurchInvLine."Quantity (Base)",
                    PurchInvLine."Direct Unit Cost", PurchInvLine."Line Discount Amount" + PurchInvLine."Inv. Discount Amount", PurchInvLine."NFB CFOP",
                    Database::"Purch. Inv. Line", 0, DocNo);
            until PurchInvLine.Next() = 0;

        AddReference(NFBDocumentHeader, PurchInvHeader."NFB Referenced Key");
        AddTransport(NFBDocumentHeader, PurchInvHeader."NFB Freight Mode", '');
        UpdateTotals(NFBDocumentHeader);
        AddPayment(NFBDocumentHeader, '', 0D);
        exit(NFBDocumentHeader."No.");
    end;

    local procedure CreateFromPurchCrMemo(DocNo: Code[20]): Code[20]
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        NFBDocumentHeader: Record "NFB Document Header";
    begin
        PurchCrMemoHdr.Get(DocNo);
        InitHeader(NFBDocumentHeader, "NFB Source Doc. Type"::"Purchase Cr. Memo", DocNo, PurchCrMemoHdr."NFB Operation Type",
            PurchCrMemoHdr."Posting Date", PurchCrMemoHdr."Location Code");
        CopyHeaderFields(NFBDocumentHeader, PurchCrMemoHdr."NFB Nature of Operation", PurchCrMemoHdr."NFB Purpose",
            PurchCrMemoHdr."NFB Presence Indicator", false, PurchCrMemoHdr."NFB Additional Info");
        FillRecipientFromVendor(NFBDocumentHeader, PurchCrMemoHdr."Pay-to Vendor No.", PurchCrMemoHdr."Pay-to Name");
        SetDestination(NFBDocumentHeader, PurchCrMemoHdr."Buy-from Country/Region Code");
        NFBDocumentHeader.Insert(true);

        PurchCrMemoLine.SetRange("Document No.", DocNo);
        PurchCrMemoLine.SetRange("NFB System Line", false);
        PurchCrMemoLine.SetFilter(Type, '<>%1', PurchCrMemoLine.Type::" ");
        PurchCrMemoLine.SetFilter(Quantity, '<>0');
        if PurchCrMemoLine.FindSet() then
            repeat
                AddLine(NFBDocumentHeader, PurchCrMemoLine."Line No.", PurchCrMemoLine."No.", PurchCrMemoLine.Type = PurchCrMemoLine.Type::Item,
                    PurchCrMemoLine.Description, PurchCrMemoLine."Unit of Measure Code", PurchCrMemoLine.Quantity, PurchCrMemoLine."Quantity (Base)",
                    PurchCrMemoLine."Direct Unit Cost", PurchCrMemoLine."Line Discount Amount" + PurchCrMemoLine."Inv. Discount Amount", PurchCrMemoLine."NFB CFOP",
                    Database::"Purch. Cr. Memo Line", 0, DocNo);
            until PurchCrMemoLine.Next() = 0;

        AddReference(NFBDocumentHeader, PurchCrMemoHdr."NFB Referenced Key");
        if PurchCrMemoHdr."Applies-to Doc. Type" = PurchCrMemoHdr."Applies-to Doc. Type"::Invoice then
            AddReferenceFromSource(NFBDocumentHeader, "NFB Source Doc. Type"::"Purchase Invoice", PurchCrMemoHdr."Applies-to Doc. No.");
        AddTransport(NFBDocumentHeader, PurchCrMemoHdr."NFB Freight Mode", '');
        UpdateTotals(NFBDocumentHeader);
        AddPayment(NFBDocumentHeader, '', 0D);
        exit(NFBDocumentHeader."No.");
    end;

    local procedure CreateFromTransferShipment(DocNo: Code[20]): Code[20]
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferShipmentLine: Record "Transfer Shipment Line";
        NFBDocumentHeader: Record "NFB Document Header";
        NFBDocumentLine: Record "NFB Document Line";
        NFBTaxRule: Record "NFB Tax Rule";
        TempCalcLine: Record "NFB Document Line" temporary;
        NFBTaxLine: Record "NFB Tax Line";
    begin
        TransferShipmentHeader.Get(DocNo);
        InitHeader(NFBDocumentHeader, "NFB Source Doc. Type"::"Transfer Shipment", DocNo, TransferShipmentHeader."NFB Operation Type",
            TransferShipmentHeader."Posting Date", TransferShipmentHeader."Transfer-from Code");
        CopyHeaderFields(NFBDocumentHeader, TransferShipmentHeader."NFB Nature of Operation", TransferShipmentHeader."NFB Purpose",
            TransferShipmentHeader."NFB Presence Indicator", false, TransferShipmentHeader."NFB Additional Info");
        FillRecipientFromLocation(NFBDocumentHeader, TransferShipmentHeader."Transfer-to Code");
        SetDestination(NFBDocumentHeader, '');
        NFBDocumentHeader.Insert(true);

        NFBTaxLine.DeleteForDocument(Database::"Transfer Shipment Line", 0, DocNo);
        TransferShipmentLine.SetRange("Document No.", DocNo);
        TransferShipmentLine.SetFilter(Quantity, '<>0');
        if TransferShipmentLine.FindSet() then
            repeat
                NFBTaxEngine.CalculateTransferShipmentLine(TransferShipmentHeader, TransferShipmentLine, NFBDocumentHeader."Destination Id",
                    NFBDocumentHeader."Recipient UF", TempCalcLine, NFBTaxRule);
                NFBTaxEngine.WriteTaxLines(Database::"Transfer Shipment Line", 0, DocNo, TransferShipmentLine."Line No.", TempCalcLine, NFBTaxRule.Code);
                if TransferShipmentLine."NFB CFOP" = '' then
                    TransferShipmentLine."NFB CFOP" := NFBTaxRule.CFOP;
                AddLine(NFBDocumentHeader, TransferShipmentLine."Line No.", TransferShipmentLine."Item No.", true,
                    TransferShipmentLine.Description, TransferShipmentLine."Unit of Measure Code", TransferShipmentLine.Quantity, TransferShipmentLine."Quantity (Base)",
                    0, 0, TransferShipmentLine."NFB CFOP", Database::"Transfer Shipment Line", 0, DocNo);
                // Transfers have no price: the line value is the cost used by the tax calculation.
                NFBDocumentLine.Get(NFBDocumentHeader."No.", TransferShipmentLine."Line No.");
                NFBDocumentLine."Products Amount" := TempCalcLine."Products Amount";
                if NFBDocumentLine."Commercial Quantity" <> 0 then
                    NFBDocumentLine."Commercial Unit Price" := NFBDocumentLine."Products Amount" / NFBDocumentLine."Commercial Quantity";
                if NFBDocumentLine."Taxable Quantity" <> 0 then
                    NFBDocumentLine."Taxable Unit Price" := NFBDocumentLine."Products Amount" / NFBDocumentLine."Taxable Quantity";
                NFBDocumentLine.Modify();
            until TransferShipmentLine.Next() = 0;

        AddReference(NFBDocumentHeader, TransferShipmentHeader."NFB Referenced Key");
        AddTransport(NFBDocumentHeader, TransferShipmentHeader."NFB Freight Mode", TransferShipmentHeader."Shipping Agent Code");
        UpdateTotals(NFBDocumentHeader);
        AddPayment(NFBDocumentHeader, '', 0D);
        exit(NFBDocumentHeader."No.");
    end;

    local procedure InitHeader(var NFBDocumentHeader: Record "NFB Document Header"; SourceDocType: Enum "NFB Source Doc. Type"; SourceDocNo: Code[20]; OperationType: Code[20]; PostingDate: Date; LocationCode: Code[10])
    var
        NFBOperationType: Record "NFB Operation Type";
    begin
        NFBSetup.GetRecordOnce();
        if OperationType = '' then
            Error(NoOperationTypeErr, SourceDocType, SourceDocNo);
        NFBOperationType.Get(OperationType);
        if not NFBOperationType."Issue NF-e" then
            Error(NoIssueErr, OperationType);

        NFBDocumentHeader.Init();
        NFBDocumentHeader."Source Doc. Type" := SourceDocType;
        NFBDocumentHeader."Source Doc. No." := SourceDocNo;
        NFBDocumentHeader.Status := NFBDocumentHeader.Status::Draft;
        NFBDocumentHeader."Issue Mode" := NFBSetup."Issue Mode";
        NFBDocumentHeader.Environment := NFBSetup.Environment;
        NFBDocumentHeader."Emission Type" := NFBSetup."Emission Type";
        NFBDocumentHeader."Posting Date" := PostingDate;
        NFBDocumentHeader."Issue DateTime" := CurrentDateTime();
        NFBDocumentHeader."Exit DateTime" := CurrentDateTime();
        NFBDocumentHeader."Operation Type" := OperationType;
        NFBDocumentHeader.Direction := NFBOperationType.Direction;
        NFBDocumentHeader.Model := '55';
        NFBDocumentHeader.Series := NFBOperationType.Series;
        if NFBDocumentHeader.Series = 0 then
            NFBDocumentHeader.Series := NFBSetup."Default Series";
        FillIssuer(NFBDocumentHeader, LocationCode);
    end;

    local procedure CopyHeaderFields(var NFBDocumentHeader: Record "NFB Document Header"; NatureOfOperation: Text[60]; Purpose: Enum "NFB Purpose"; PresenceIndicator: Enum "NFB Presence Indicator"; FinalConsumer: Boolean; AdditionalInfo: Text[250])
    var
        NFBOperationType: Record "NFB Operation Type";
    begin
        NFBOperationType.Get(NFBDocumentHeader."Operation Type");
        NFBDocumentHeader."Nature of Operation" := NatureOfOperation;
        if NFBDocumentHeader."Nature of Operation" = '' then
            NFBDocumentHeader."Nature of Operation" := NFBOperationType."Nature of Operation";
        NFBDocumentHeader.Purpose := Purpose;
        NFBDocumentHeader."Presence Indicator" := PresenceIndicator;
        NFBDocumentHeader."Final Consumer" := FinalConsumer;
        NFBDocumentHeader."Additional Info" := AdditionalInfo;
    end;

    local procedure FillIssuer(var NFBDocumentHeader: Record "NFB Document Header"; LocationCode: Code[10])
    var
        CompanyInformation: Record "Company Information";
        Location: Record Location;
    begin
        CompanyInformation.Get();
        NFBDocumentHeader."Issuer Name" := CopyStr(CompanyInformation.Name, 1, MaxStrLen(NFBDocumentHeader."Issuer Name"));
        NFBDocumentHeader."Issuer CRT" := CompanyInformation."NFB Tax Regime";
        NFBDocumentHeader."Issuer CNPJ" := CompanyInformation."NFB CNPJ";
        NFBDocumentHeader."Issuer IE" := CompanyInformation."NFB IE";
        NFBDocumentHeader."Issuer UF" := CompanyInformation."NFB UF";
        NFBDocumentHeader."Taxable Event Municipality" := CompanyInformation."NFB Municipality Code";
        if Location.Get(LocationCode) and (Location."NFB CNPJ" <> '') then begin
            NFBDocumentHeader."Issuer Location Code" := Location.Code;
            NFBDocumentHeader."Issuer CNPJ" := Location."NFB CNPJ";
            NFBDocumentHeader."Issuer IE" := Location."NFB IE";
            NFBDocumentHeader."Issuer UF" := Location."NFB UF";
            NFBDocumentHeader."Taxable Event Municipality" := Location."NFB Municipality Code";
        end;
        NFBDocumentHeader."Issuer UF Code" := CopyStr(NFBDocumentHeader."Taxable Event Municipality", 1, 2);
    end;

    local procedure FillRecipientFromCustomer(var NFBDocumentHeader: Record "NFB Document Header"; CustomerNo: Code[20]; Name: Text)
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        NFBDocumentHeader."Recipient No." := Customer."No.";
        NFBDocumentHeader."Recipient Type" := Customer."NFB Person Type";
        NFBDocumentHeader."Recipient CPF/CNPJ" := Customer."NFB CPF/CNPJ";
        NFBDocumentHeader."Recipient Foreign Id" := Customer."NFB Foreign Id";
        NFBDocumentHeader."Recipient IE Indicator" := Customer."NFB IE Indicator";
        NFBDocumentHeader."Recipient IE" := Customer."NFB IE";
        NFBDocumentHeader."Recipient SUFRAMA" := Customer."NFB SUFRAMA";
        SetRecipientAddress(NFBDocumentHeader, Name, Customer.Address, Customer."NFB Address No.", Customer."Address 2", Customer."NFB District",
            Customer."NFB Municipality Code", Customer.City, Customer."NFB UF", Customer."Post Code", Customer."Country/Region Code", Customer."Phone No.");
        NFBDocumentHeader."Recipient E-Mail" := Customer."NFB XML E-Mail";
        if NFBDocumentHeader."Recipient E-Mail" = '' then
            NFBDocumentHeader."Recipient E-Mail" := CopyStr(Customer."E-Mail", 1, MaxStrLen(NFBDocumentHeader."Recipient E-Mail"));
    end;

    local procedure FillRecipientFromVendor(var NFBDocumentHeader: Record "NFB Document Header"; VendorNo: Code[20]; Name: Text)
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        NFBDocumentHeader."Recipient No." := Vendor."No.";
        NFBDocumentHeader."Recipient Type" := Vendor."NFB Person Type";
        NFBDocumentHeader."Recipient CPF/CNPJ" := Vendor."NFB CPF/CNPJ";
        NFBDocumentHeader."Recipient Foreign Id" := Vendor."NFB Foreign Id";
        NFBDocumentHeader."Recipient IE Indicator" := Vendor."NFB IE Indicator";
        NFBDocumentHeader."Recipient IE" := Vendor."NFB IE";
        SetRecipientAddress(NFBDocumentHeader, Name, Vendor.Address, Vendor."NFB Address No.", Vendor."Address 2", Vendor."NFB District",
            Vendor."NFB Municipality Code", Vendor.City, Vendor."NFB UF", Vendor."Post Code", Vendor."Country/Region Code", Vendor."Phone No.");
        NFBDocumentHeader."Recipient E-Mail" := CopyStr(Vendor."E-Mail", 1, MaxStrLen(NFBDocumentHeader."Recipient E-Mail"));
    end;

    local procedure FillRecipientFromLocation(var NFBDocumentHeader: Record "NFB Document Header"; LocationCode: Code[10])
    var
        Location: Record Location;
        CompanyInformation: Record "Company Information";
    begin
        Location.Get(LocationCode);
        CompanyInformation.Get();
        NFBDocumentHeader."Recipient No." := Location.Code;
        NFBDocumentHeader."Recipient Type" := NFBDocumentHeader."Recipient Type"::"Legal Entity";
        NFBDocumentHeader."Recipient CPF/CNPJ" := Location."NFB CNPJ";
        NFBDocumentHeader."Recipient IE" := Location."NFB IE";
        NFBDocumentHeader."Recipient IE Indicator" := NFBDocumentHeader."Recipient IE Indicator"::Contributor;
        SetRecipientAddress(NFBDocumentHeader, CompanyInformation.Name, Location.Address, Location."NFB Address No.", Location."Address 2", Location."NFB District",
            Location."NFB Municipality Code", Location.City, Location."NFB UF", Location."Post Code", Location."Country/Region Code", Location."Phone No.");
    end;

    local procedure SetRecipientAddress(var NFBDocumentHeader: Record "NFB Document Header"; Name: Text; Address: Text; AddressNo: Text; Address2: Text; District: Text; MunicipalityCode: Code[7]; City: Text; UF: Code[2]; PostCode: Code[20]; CountryCode: Code[10]; Phone: Text)
    var
        CountryRegion: Record "Country/Region";
    begin
        NFBDocumentHeader."Recipient Name" := CopyStr(Name, 1, MaxStrLen(NFBDocumentHeader."Recipient Name"));
        NFBDocumentHeader."Recipient Address" := CopyStr(Address, 1, MaxStrLen(NFBDocumentHeader."Recipient Address"));
        NFBDocumentHeader."Recipient Address No." := CopyStr(AddressNo, 1, MaxStrLen(NFBDocumentHeader."Recipient Address No."));
        if NFBDocumentHeader."Recipient Address No." = '' then
            NFBDocumentHeader."Recipient Address No." := 'S/N';
        NFBDocumentHeader."Recipient Address 2" := CopyStr(Address2, 1, MaxStrLen(NFBDocumentHeader."Recipient Address 2"));
        NFBDocumentHeader."Recipient District" := CopyStr(District, 1, MaxStrLen(NFBDocumentHeader."Recipient District"));
        NFBDocumentHeader."Recipient Municipality Code" := MunicipalityCode;
        NFBDocumentHeader."Recipient City" := CopyStr(City, 1, MaxStrLen(NFBDocumentHeader."Recipient City"));
        NFBDocumentHeader."Recipient UF" := UF;
        NFBDocumentHeader."Recipient Post Code" := CopyStr(NFBValidation.OnlyDigits(PostCode), 1, MaxStrLen(NFBDocumentHeader."Recipient Post Code"));
        NFBDocumentHeader."Recipient Phone" := CopyStr(NFBValidation.OnlyDigits(Phone), 1, MaxStrLen(NFBDocumentHeader."Recipient Phone"));
        NFBDocumentHeader."Recipient BACEN Code" := '1058';
        NFBDocumentHeader."Recipient Country" := 'BRASIL';
        if CountryRegion.Get(CountryCode) then
            if CountryRegion."NFB BACEN Code" <> '' then begin
                NFBDocumentHeader."Recipient BACEN Code" := CountryRegion."NFB BACEN Code";
                NFBDocumentHeader."Recipient Country" := CopyStr(CountryRegion.Name, 1, MaxStrLen(NFBDocumentHeader."Recipient Country"));
            end;
        if NFBDocumentHeader."Recipient Type" = NFBDocumentHeader."Recipient Type"::Foreign then begin
            NFBDocumentHeader."Recipient Municipality Code" := '9999999';
            NFBDocumentHeader."Recipient City" := ForeignCityTxt;
            NFBDocumentHeader."Recipient UF" := 'EX';
            NFBDocumentHeader."Recipient IE Indicator" := NFBDocumentHeader."Recipient IE Indicator"::"Non-Contributor";
        end;
    end;

    local procedure SetDestination(var NFBDocumentHeader: Record "NFB Document Header"; CountryCode: Code[10])
    var
        NFBOperationMgt: Codeunit "NFB Operation Mgt";
    begin
        if NFBDocumentHeader."Recipient Type" = NFBDocumentHeader."Recipient Type"::Foreign then
            NFBDocumentHeader."Destination Id" := NFBDocumentHeader."Destination Id"::Exterior
        else
            NFBDocumentHeader."Destination Id" := NFBOperationMgt.GetDestinationId(NFBDocumentHeader."Issuer UF", NFBDocumentHeader."Recipient UF", CountryCode);
        if NFBDocumentHeader."Recipient IE Indicator" = NFBDocumentHeader."Recipient IE Indicator"::"Non-Contributor" then
            if NFBDocumentHeader.Direction = NFBDocumentHeader.Direction::Outbound then
                NFBDocumentHeader."Final Consumer" := true;
    end;

    local procedure AddLine(NFBDocumentHeader: Record "NFB Document Header"; SourceLineNo: Integer; No: Code[20]; IsItem: Boolean; Description: Text; UnitOfMeasureCode: Code[10]; Quantity: Decimal; QuantityBase: Decimal; UnitPrice: Decimal; DiscountAmount: Decimal; Cfop: Code[4]; TaxTableID: Integer; TaxDocType: Integer; TaxDocNo: Code[20])
    var
        NFBDocumentLine: Record "NFB Document Line";
        Item: Record Item;
        NFBImportDeclaration: Record "NFB Import Declaration";
        DocImportDeclaration: Record "NFB Import Declaration";
    begin
        NFBDocumentLine.SetRange("Document No.", NFBDocumentHeader."No.");
        NFBDocumentLine.Init();
        NFBDocumentLine."Document No." := NFBDocumentHeader."No.";
        NFBDocumentLine."Line No." := SourceLineNo;
        NFBDocumentLine."Item Seq." := NFBDocumentLine.Count() + 1;
        NFBDocumentLine."Source Line No." := SourceLineNo;
        NFBDocumentLine."Product Code" := No;
        NFBDocumentLine.Description := CopyStr(Description, 1, MaxStrLen(NFBDocumentLine.Description));
        NFBDocumentLine.CFOP := Cfop;
        NFBDocumentLine."Commercial Unit" := GetSefazUnit(UnitOfMeasureCode);
        NFBDocumentLine."Commercial Quantity" := Quantity;
        NFBDocumentLine."Commercial Unit Price" := UnitPrice;
        NFBDocumentLine."Products Amount" := Round(Quantity * UnitPrice, 0.01);
        NFBDocumentLine."Discount Amount" := Round(DiscountAmount, 0.01);
        NFBDocumentLine."Taxable Unit" := NFBDocumentLine."Commercial Unit";
        NFBDocumentLine."Taxable Quantity" := Quantity;
        NFBDocumentLine."Taxable Unit Price" := UnitPrice;
        NFBDocumentLine.GTIN := 'SEM GTIN';
        if IsItem and Item.Get(No) then begin
            NFBDocumentLine.NCM := Item."NFB NCM";
            NFBDocumentLine.CEST := Item."NFB CEST";
            NFBDocumentLine."Ex TIPI" := Item."NFB Ex TIPI";
            NFBDocumentLine.Origin := Item."NFB Origin";
            if Item."NFB GTIN" <> '' then
                NFBDocumentLine.GTIN := Item."NFB GTIN";
            if Item."NFB Taxable Unit" <> '' then begin
                NFBDocumentLine."Taxable Unit" := GetSefazUnit(Item."NFB Taxable Unit");
                NFBDocumentLine."Taxable Quantity" := Round(QuantityBase * Item."NFB Taxable Unit Factor", 0.0001);
                if NFBDocumentLine."Taxable Quantity" <> 0 then
                    NFBDocumentLine."Taxable Unit Price" := NFBDocumentLine."Products Amount" / NFBDocumentLine."Taxable Quantity";
            end;
        end;
        NFBTaxEngine.ApplyTaxLines(NFBDocumentLine, TaxTableID, TaxDocType, TaxDocNo, SourceLineNo);

        if NFBImportDeclaration.Get(TaxTableID, TaxDocType, TaxDocNo, SourceLineNo) then begin
            DocImportDeclaration := NFBImportDeclaration;
            DocImportDeclaration."Table ID" := Database::"NFB Document Line";
            DocImportDeclaration."Document Type" := 0;
            DocImportDeclaration."Document No." := NFBDocumentLine."Document No.";
            DocImportDeclaration."Line No." := NFBDocumentLine."Line No.";
            DocImportDeclaration.Insert();
            NFBDocumentLine."II Customs Expenses" := NFBImportDeclaration."Customs Expenses";
            NFBDocumentLine."IOF Amount" := NFBImportDeclaration."IOF Amount";
        end;
        NFBDocumentLine.Insert();
    end;

    local procedure AddReference(NFBDocumentHeader: Record "NFB Document Header"; AccessKey: Code[44])
    var
        NFBDocumentReference: Record "NFB Document Reference";
    begin
        if AccessKey = '' then
            exit;
        NFBDocumentReference.SetRange("Document No.", NFBDocumentHeader."No.");
        NFBDocumentReference.SetRange("Referenced Access Key", AccessKey);
        if not NFBDocumentReference.IsEmpty() then
            exit;
        NFBDocumentReference.SetRange("Referenced Access Key");
        NFBDocumentReference."Document No." := NFBDocumentHeader."No.";
        NFBDocumentReference."Line No." := (NFBDocumentReference.Count() + 1) * 10000;
        NFBDocumentReference."Referenced Access Key" := AccessKey;
        NFBDocumentReference.Insert();
    end;

    local procedure AddReferenceFromSource(NFBDocumentHeader: Record "NFB Document Header"; SourceDocType: Enum "NFB Source Doc. Type"; SourceDocNo: Code[20])
    var
        ReferencedHeader: Record "NFB Document Header";
        NFBDocumentReference: Record "NFB Document Reference";
    begin
        if SourceDocNo = '' then
            exit;
        ReferencedHeader.SetRange("Source Doc. Type", SourceDocType);
        ReferencedHeader.SetRange("Source Doc. No.", SourceDocNo);
        ReferencedHeader.SetRange(Status, ReferencedHeader.Status::Authorized);
        if not ReferencedHeader.FindFirst() then
            exit;
        AddReference(NFBDocumentHeader, ReferencedHeader."Access Key");
        NFBDocumentReference.SetRange("Document No.", NFBDocumentHeader."No.");
        NFBDocumentReference.SetRange("Referenced Access Key", ReferencedHeader."Access Key");
        if NFBDocumentReference.FindFirst() then begin
            NFBDocumentReference."Referenced Document No." := ReferencedHeader."No.";
            NFBDocumentReference.Modify();
        end;
    end;

    local procedure AddTransport(NFBDocumentHeader: Record "NFB Document Header"; FreightMode: Enum "NFB Freight Mode"; ShippingAgentCode: Code[10])
    var
        NFBDocumentTransport: Record "NFB Document Transport";
        ShippingAgent: Record "Shipping Agent";
        Vendor: Record Vendor;
    begin
        NFBDocumentTransport.Init();
        NFBDocumentTransport."Document No." := NFBDocumentHeader."No.";
        NFBDocumentTransport."Freight Mode" := FreightMode;
        if ShippingAgent.Get(ShippingAgentCode) then begin
            NFBDocumentTransport."Vehicle Plate" := ShippingAgent."NFB Vehicle Plate";
            NFBDocumentTransport."Vehicle UF" := ShippingAgent."NFB Vehicle UF";
            NFBDocumentTransport."Carrier Name" := CopyStr(ShippingAgent.Name, 1, MaxStrLen(NFBDocumentTransport."Carrier Name"));
            if Vendor.Get(ShippingAgent."NFB Vendor No.") then begin
                NFBDocumentTransport."Carrier CPF/CNPJ" := Vendor."NFB CPF/CNPJ";
                NFBDocumentTransport."Carrier Name" := CopyStr(Vendor.Name, 1, MaxStrLen(NFBDocumentTransport."Carrier Name"));
                NFBDocumentTransport."Carrier IE" := Vendor."NFB IE";
                NFBDocumentTransport."Carrier Address" := CopyStr(Vendor.Address, 1, MaxStrLen(NFBDocumentTransport."Carrier Address"));
                NFBDocumentTransport."Carrier City" := CopyStr(Vendor.City, 1, MaxStrLen(NFBDocumentTransport."Carrier City"));
                NFBDocumentTransport."Carrier UF" := Vendor."NFB UF";
            end;
        end;
        NFBDocumentTransport.Insert();
    end;

    local procedure AddPayment(var NFBDocumentHeader: Record "NFB Document Header"; PaymentMethodCode: Code[10]; DueDate: Date)
    var
        NFBDocumentPayment: Record "NFB Document Payment";
        NFBDocumentInstallment: Record "NFB Document Installment";
        PaymentMethod: Record "Payment Method";
    begin
        NFBDocumentPayment.Init();
        NFBDocumentPayment."Document No." := NFBDocumentHeader."No.";
        NFBDocumentPayment."Line No." := 10000;
        // Returns, adjustments and documents with no sale carry tPag 90 (no payment) and vPag 0.
        if (NFBDocumentHeader.Purpose <> NFBDocumentHeader.Purpose::Normal) or
           (NFBDocumentHeader."Source Doc. Type" in [NFBDocumentHeader."Source Doc. Type"::"Transfer Shipment", NFBDocumentHeader."Source Doc. Type"::"Purchase Cr. Memo", NFBDocumentHeader."Source Doc. Type"::"Purchase Invoice"]) or
           (PaymentMethodCode = '') and (DueDate = 0D)
        then begin
            NFBDocumentPayment."Payment Type" := '90';
            NFBDocumentPayment.Amount := 0;
            NFBDocumentPayment.Insert();
            exit;
        end;

        NFBDocumentPayment.Amount := NFBDocumentHeader."Invoice Amount";
        NFBDocumentPayment."Payment Type" := '15';
        if PaymentMethod.Get(PaymentMethodCode) then
            if PaymentMethod."NFB Payment Type" <> '' then begin
                NFBDocumentPayment."Payment Type" := PaymentMethod."NFB Payment Type";
                NFBDocumentPayment.Description := PaymentMethod."NFB Payment Description";
            end;
        if DueDate > NFBDocumentHeader."Posting Date" then
            NFBDocumentPayment."Payment Indicator" := NFBDocumentPayment."Payment Indicator"::Term;
        NFBDocumentPayment.Insert();

        if NFBDocumentPayment."Payment Indicator" = NFBDocumentPayment."Payment Indicator"::Term then begin
            NFBDocumentInstallment."Document No." := NFBDocumentHeader."No.";
            NFBDocumentInstallment."Line No." := 10000;
            NFBDocumentInstallment."Installment No." := '001';
            NFBDocumentInstallment."Due Date" := DueDate;
            NFBDocumentInstallment.Amount := NFBDocumentHeader."Invoice Amount";
            NFBDocumentInstallment.Insert();
        end;
    end;

    procedure UpdateTotals(var NFBDocumentHeader: Record "NFB Document Header")
    var
        NFBDocumentLine: Record "NFB Document Line";
    begin
        NFBDocumentHeader."ICMS Base" := 0;
        NFBDocumentHeader."ICMS Amount" := 0;
        NFBDocumentHeader."FCP Amount" := 0;
        NFBDocumentHeader."ICMS ST Base" := 0;
        NFBDocumentHeader."ICMS ST Amount" := 0;
        NFBDocumentHeader."FCP ST Amount" := 0;
        NFBDocumentHeader."DIFAL Dest. Amount" := 0;
        NFBDocumentHeader."FCP Dest. Amount" := 0;
        NFBDocumentHeader."Products Amount" := 0;
        NFBDocumentHeader."Freight Amount" := 0;
        NFBDocumentHeader."Insurance Amount" := 0;
        NFBDocumentHeader."Discount Amount" := 0;
        NFBDocumentHeader."II Amount" := 0;
        NFBDocumentHeader."IPI Amount" := 0;
        NFBDocumentHeader."PIS Amount" := 0;
        NFBDocumentHeader."COFINS Amount" := 0;
        NFBDocumentHeader."Other Expenses" := 0;
        NFBDocumentHeader."Invoice Amount" := 0;
        NFBDocumentHeader."IBS/CBS Base" := 0;
        NFBDocumentHeader."IBS UF Amount" := 0;
        NFBDocumentHeader."IBS Mun. Amount" := 0;
        NFBDocumentHeader."CBS Amount" := 0;

        NFBDocumentLine.SetRange("Document No.", NFBDocumentHeader."No.");
        if NFBDocumentLine.FindSet() then
            repeat
                NFBDocumentHeader."ICMS Base" += NFBDocumentLine."ICMS Base";
                NFBDocumentHeader."ICMS Amount" += NFBDocumentLine."ICMS Amount";
                NFBDocumentHeader."FCP Amount" += NFBDocumentLine."FCP Amount";
                NFBDocumentHeader."ICMS ST Base" += NFBDocumentLine."ICMS ST Base";
                NFBDocumentHeader."ICMS ST Amount" += NFBDocumentLine."ICMS ST Amount";
                NFBDocumentHeader."FCP ST Amount" += NFBDocumentLine."FCP ST Amount";
                NFBDocumentHeader."DIFAL Dest. Amount" += NFBDocumentLine."DIFAL Dest. Amount";
                NFBDocumentHeader."FCP Dest. Amount" += NFBDocumentLine."FCP Dest. Amount";
                if NFBDocumentLine."Include in Total" then
                    NFBDocumentHeader."Products Amount" += NFBDocumentLine."Products Amount";
                NFBDocumentHeader."Freight Amount" += NFBDocumentLine."Freight Amount";
                NFBDocumentHeader."Insurance Amount" += NFBDocumentLine."Insurance Amount";
                NFBDocumentHeader."Discount Amount" += NFBDocumentLine."Discount Amount";
                NFBDocumentHeader."II Amount" += NFBDocumentLine."II Amount";
                NFBDocumentHeader."IPI Amount" += NFBDocumentLine."IPI Amount";
                NFBDocumentHeader."PIS Amount" += NFBDocumentLine."PIS Amount";
                NFBDocumentHeader."COFINS Amount" += NFBDocumentLine."COFINS Amount";
                NFBDocumentHeader."Other Expenses" += NFBDocumentLine."Other Expenses";
                NFBDocumentHeader."Invoice Amount" += NFBDocumentLine.LineTotal();
                NFBDocumentHeader."IBS/CBS Base" += NFBDocumentLine."IBS/CBS Base";
                NFBDocumentHeader."IBS UF Amount" += NFBDocumentLine."IBS UF Amount";
                NFBDocumentHeader."IBS Mun. Amount" += NFBDocumentLine."IBS Mun. Amount";
                NFBDocumentHeader."CBS Amount" += NFBDocumentLine."CBS Amount";
            until NFBDocumentLine.Next() = 0;
        NFBDocumentHeader.Modify();
    end;

    local procedure GetSefazUnit(UnitOfMeasureCode: Code[10]): Code[6]
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if UnitOfMeasure.Get(UnitOfMeasureCode) then
            if UnitOfMeasure."NFB SEFAZ Code" <> '' then
                exit(UnitOfMeasure."NFB SEFAZ Code");
        exit(CopyStr(UnitOfMeasureCode, 1, 6));
    end;
}
