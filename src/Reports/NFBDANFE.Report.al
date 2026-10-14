report 50100 "NFB DANFE"
{
    Caption = 'DANFE';
    UsageCategory = None;
    DefaultRenderingLayout = DANFE;

    dataset
    {
        dataitem(Header; "NFB Document Header")
        {
            RequestFilterFields = "No.";

            column(DocumentNo; Header."No.") { }
            column(NFNo; NFNoText) { }
            column(Series; Format(Header.Series)) { }
            column(TpNF; Format(Header.Direction.AsInteger())) { }
            column(AccessKeyFormatted; AccessKeyFormatted) { }
            column(AccessKeyBarcode; AccessKeyBarcode) { }
            column(ProtocolText; ProtocolText) { }
            column(NatOp; Header."Nature of Operation") { }
            column(IssuerName; Header."Issuer Name") { }
            column(IssuerAddress1; IssuerAddress[1]) { }
            column(IssuerAddress2; IssuerAddress[2]) { }
            column(IssuerAddress3; IssuerAddress[3]) { }
            column(IssuerIE; Header."Issuer IE") { }
            column(IssuerIEST; IssuerIEST) { }
            column(IssuerCNPJ; FormatCpfCnpj(Header."Issuer CNPJ")) { }
            column(StubText; StubText) { }
            column(RecipientName; Header."Recipient Name") { }
            column(RecipientDoc; RecipientDoc) { }
            column(RecipientAddress; RecipientAddress) { }
            column(RecipientDistrict; Header."Recipient District") { }
            column(RecipientPostCode; FormatPostCode(Header."Recipient Post Code")) { }
            column(RecipientCity; Header."Recipient City") { }
            column(RecipientPhone; Header."Recipient Phone") { }
            column(RecipientUF; Header."Recipient UF") { }
            column(RecipientIE; Header."Recipient IE") { }
            column(IssueDate; IssueDateText) { }
            column(ExitDate; ExitDateText) { }
            column(ExitTime; ExitTimeText) { }
            column(InstallmentsText; InstallmentsText) { }
            column(ICMSBase; FormatAmount(Header."ICMS Base")) { }
            column(ICMSAmount; FormatAmount(Header."ICMS Amount")) { }
            column(STBase; FormatAmount(Header."ICMS ST Base")) { }
            column(STAmount; FormatAmount(Header."ICMS ST Amount")) { }
            column(IIAmount; FormatAmount(Header."II Amount")) { }
            column(FCPAmount; FormatAmount(Header."FCP Amount")) { }
            column(FCPDestAmount; FormatAmount(Header."FCP Dest. Amount")) { }
            column(DIFALDestAmount; FormatAmount(Header."DIFAL Dest. Amount")) { }
            column(PISAmount; FormatAmount(Header."PIS Amount")) { }
            column(COFINSAmount; FormatAmount(Header."COFINS Amount")) { }
            column(ProductsAmount; FormatAmount(Header."Products Amount")) { }
            column(FreightAmount; FormatAmount(Header."Freight Amount")) { }
            column(InsuranceAmount; FormatAmount(Header."Insurance Amount")) { }
            column(DiscountAmount; FormatAmount(Header."Discount Amount")) { }
            column(OtherExpenses; FormatAmount(Header."Other Expenses")) { }
            column(IPIAmount; FormatAmount(Header."IPI Amount")) { }
            column(InvoiceAmount; FormatAmount(Header."Invoice Amount")) { }
            column(IBSCBSBase; FormatAmount(Header."IBS/CBS Base")) { }
            column(IBSUFAmount; FormatAmount(Header."IBS UF Amount")) { }
            column(IBSMunAmount; FormatAmount(Header."IBS Mun. Amount")) { }
            column(CBSAmount; FormatAmount(Header."CBS Amount")) { }
            column(FreightModeText; FreightModeText) { }
            column(CarrierName; NFBDocumentTransport."Carrier Name") { }
            column(CarrierDoc; FormatCpfCnpj(NFBDocumentTransport."Carrier CPF/CNPJ")) { }
            column(CarrierIE; NFBDocumentTransport."Carrier IE") { }
            column(CarrierAddress; NFBDocumentTransport."Carrier Address") { }
            column(CarrierCity; NFBDocumentTransport."Carrier City") { }
            column(CarrierUF; NFBDocumentTransport."Carrier UF") { }
            column(VehiclePlate; NFBDocumentTransport."Vehicle Plate") { }
            column(VehicleUF; NFBDocumentTransport."Vehicle UF") { }
            column(VolumeQuantity; VolumeQuantityText) { }
            column(VolumeKind; NFBDocumentTransport."Volume Kind") { }
            column(VolumeBrand; NFBDocumentTransport.Brand) { }
            column(GrossWeight; FormatDecimal(NFBDocumentTransport."Gross Weight", 3)) { }
            column(NetWeight; FormatDecimal(NFBDocumentTransport."Net Weight", 3)) { }
            column(AdditionalInfo; AdditionalInfoText) { }
            column(FiscalInfo; Header."Fiscal Info") { }
            column(IsHomologation; IsHomologation) { }
            column(NotAuthorized; NotAuthorized) { }

            dataitem(Line; "NFB Document Line")
            {
                DataItemLink = "Document No." = field("No.");
                DataItemTableView = sorting("Document No.", "Item Seq.");

                column(LineCode; Line."Product Code") { }
                column(LineDescription; LineDescription) { }
                column(LineNCM; Line.NCM) { }
                column(LineCST; LineCST) { }
                column(LineCFOP; Line.CFOP) { }
                column(LineUnit; Line."Commercial Unit") { }
                column(LineQuantity; FormatDecimal(Line."Commercial Quantity", 4)) { }
                column(LineUnitPrice; FormatDecimal(Line."Commercial Unit Price", 4)) { }
                column(LineAmount; FormatAmount(Line."Products Amount")) { }
                column(LineDiscount; FormatAmount(Line."Discount Amount")) { }
                column(LineICMSBase; FormatAmount(Line."ICMS Base")) { }
                column(LineICMSAmount; FormatAmount(Line."ICMS Amount")) { }
                column(LineIPIAmount; FormatAmount(Line."IPI Amount")) { }
                column(LineICMSPct; FormatDecimal(Line."ICMS %", 2)) { }
                column(LineIPIPct; FormatDecimal(Line."IPI %", 2)) { }

                trigger OnAfterGetRecord()
                begin
                    LineDescription := Line.Description;
                    if Line."Additional Info" <> '' then
                        LineDescription += ' - ' + Line."Additional Info";
                    LineCST := Format(Line.Origin.AsInteger()) + Line."ICMS CST";
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Header.TestField("Access Key");
                PrepareHeader();
            end;
        }
    }

    rendering
    {
        layout(DANFE)
        {
            Type = RDLC;
            LayoutFile = './src/Reports/Layouts/NFBDANFE.rdlc';
            Caption = 'DANFE (portrait)';
        }
    }

    var
        NFBDocumentTransport: Record "NFB Document Transport";
        NFBXMLBuilder: Codeunit "NFB XML Builder";
        NFBValidation: Codeunit "NFB Validation";
        IssuerAddress: array[3] of Text;
        NFNoText: Text;
        AccessKeyFormatted: Text;
        AccessKeyBarcode: Text;
        ProtocolText: Text;
        IssuerIEST: Text;
        StubText: Text;
        RecipientDoc: Text;
        RecipientAddress: Text;
        IssueDateText: Text;
        ExitDateText: Text;
        ExitTimeText: Text;
        InstallmentsText: Text;
        FreightModeText: Text;
        VolumeQuantityText: Text;
        AdditionalInfoText: Text;
        LineDescription: Text;
        LineCST: Text;
        IsHomologation: Boolean;
        NotAuthorized: Boolean;
        StubTxt: Label 'RECEBEMOS DE %1 OS PRODUTOS E/OU SERVIÇOS CONSTANTES DA NOTA FISCAL ELETRÔNICA INDICADA AO LADO. EMISSÃO: %2. VALOR TOTAL: R$ %3. DESTINATÁRIO: %4.', Comment = '%1 = issuer, %2 = issue date, %3 = total, %4 = recipient';
        ProtocolTxt: Label '%1 - %2', Locked = true;
        PostCodePhoneTxt: Label 'CEP %1 - Fone %2', Comment = '%1 = post code, %2 = phone';
        InstallmentTxt: Label '%1  %2  R$ %3', Locked = true;
        NotAuthorizedTxt: Label 'NF-e ainda não autorizada pela SEFAZ - sem valor fiscal';

    local procedure PrepareHeader()
    var
        CompanyInformation: Record "Company Information";
        Location: Record Location;
        NFBDocumentInstallment: Record "NFB Document Installment";
        Street: Text;
        AddressNo: Text;
        Address2: Text;
        District: Text;
        City: Text;
        UF: Text;
        PostCode: Text;
        Phone: Text;
    begin
        IsHomologation := Header.Environment = Header.Environment::Homologation;
        NotAuthorized := Header.Status <> Header.Status::Authorized;
        NFNoText := FormatNFNo(Header."NF No.");
        AccessKeyFormatted := FormatAccessKey(Header."Access Key");
        AccessKeyBarcode := EncodeBarcode(Header."Access Key");
        ProtocolText := NotAuthorizedTxt;
        if Header."Protocol No." <> '' then
            ProtocolText := StrSubstNo(ProtocolTxt, Header."Protocol No.", FormatDateTime(Header."Authorization DateTime"));

        CompanyInformation.Get();
        Street := CompanyInformation.Address;
        AddressNo := CompanyInformation."NFB Address No.";
        Address2 := CompanyInformation."Address 2";
        District := CompanyInformation."NFB District";
        City := CompanyInformation.City;
        UF := CompanyInformation."NFB UF";
        PostCode := CompanyInformation."Post Code";
        Phone := CompanyInformation."Phone No.";
        IssuerIEST := CompanyInformation."NFB ST IE";
        if (Header."Issuer Location Code" <> '') and Location.Get(Header."Issuer Location Code") then begin
            Street := Location.Address;
            AddressNo := Location."NFB Address No.";
            Address2 := Location."Address 2";
            District := Location."NFB District";
            City := Location.City;
            UF := Location."NFB UF";
            PostCode := Location."Post Code";
            if Location."Phone No." <> '' then
                Phone := Location."Phone No.";
        end;
        IssuerAddress[1] := JoinText(JoinText(Street, AddressNo, ', '), Address2, ' - ');
        IssuerAddress[2] := JoinText(JoinText(District, City, ' - '), UF, ' - ');
        IssuerAddress[3] := StrSubstNo(PostCodePhoneTxt, FormatPostCode(PostCode), Phone);

        StubText := StrSubstNo(StubTxt, Header."Issuer Name", FormatDate(DT2Date(Header."Issue DateTime")), FormatAmount(Header."Invoice Amount"), Header."Recipient Name");
        if Header."Recipient Type" = Header."Recipient Type"::Foreign then
            RecipientDoc := Header."Recipient Foreign Id"
        else
            RecipientDoc := FormatCpfCnpj(Header."Recipient CPF/CNPJ");
        RecipientAddress := JoinText(JoinText(Header."Recipient Address", Header."Recipient Address No.", ', '), Header."Recipient Address 2", ' - ');
        IssueDateText := FormatDate(DT2Date(Header."Issue DateTime"));
        ExitDateText := '';
        ExitTimeText := '';
        if Header."Exit DateTime" <> 0DT then begin
            ExitDateText := FormatDate(DT2Date(Header."Exit DateTime"));
            ExitTimeText := Format(DT2Time(Header."Exit DateTime"), 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>');
        end;

        InstallmentsText := '';
        NFBDocumentInstallment.SetRange("Document No.", Header."No.");
        if NFBDocumentInstallment.FindSet() then
            repeat
                InstallmentsText := JoinText(InstallmentsText,
                    StrSubstNo(InstallmentTxt, NFBDocumentInstallment."Installment No.", FormatDate(NFBDocumentInstallment."Due Date"), FormatAmount(NFBDocumentInstallment.Amount)),
                    '     ');
            until NFBDocumentInstallment.Next() = 0;

        if not NFBDocumentTransport.Get(Header."No.") then begin
            Clear(NFBDocumentTransport);
            NFBDocumentTransport."Freight Mode" := NFBDocumentTransport."Freight Mode"::"No Freight";
        end;
        FreightModeText := Format(NFBDocumentTransport."Freight Mode");
        VolumeQuantityText := '';
        if NFBDocumentTransport."Volume Quantity" <> 0 then
            VolumeQuantityText := Format(NFBDocumentTransport."Volume Quantity");

        AdditionalInfoText := Header."Additional Info";
        if Header."Fiscal Info" <> '' then
            AdditionalInfoText := JoinText(AdditionalInfoText, Header."Fiscal Info", ' ');
    end;

    local procedure EncodeBarcode(AccessKey: Code[44]): Text
    var
        BarcodeEncodeSettings: Record "Barcode Encode Settings";
        BarcodeFontProvider: Interface "Barcode Font Provider";
    begin
        // CODE-128C, as required by the DANFE layout of the MOC. Printed with the IDAutomation Code 128 font.
        BarcodeFontProvider := Enum::"Barcode Font Provider"::IDAutomation1D;
        BarcodeEncodeSettings."Code Set" := BarcodeEncodeSettings."Code Set"::C;
        exit(BarcodeFontProvider.EncodeFont(AccessKey, Enum::"Barcode Symbology"::Code128, BarcodeEncodeSettings));
    end;

    local procedure FormatAccessKey(AccessKey: Text) Result: Text
    var
        I: Integer;
    begin
        for I := 1 to StrLen(AccessKey) do begin
            Result += CopyStr(AccessKey, I, 1);
            if (I mod 4 = 0) and (I < StrLen(AccessKey)) then
                Result += ' ';
        end;
    end;

    local procedure FormatNFNo(NFNo: Integer): Text
    var
        Digits: Text;
    begin
        Digits := PadStr('', 9 - StrLen(Format(NFNo, 0, 9)), '0') + Format(NFNo, 0, 9);
        exit(CopyStr(Digits, 1, 3) + '.' + CopyStr(Digits, 4, 3) + '.' + CopyStr(Digits, 7, 3));
    end;

    local procedure FormatCpfCnpj(Value: Text): Text
    var
        Digits: Text;
    begin
        Digits := NFBValidation.OnlyDigits(Value);
        case StrLen(Digits) of
            14:
                exit(StrSubstNo('%1.%2.%3/%4-%5', CopyStr(Digits, 1, 2), CopyStr(Digits, 3, 3), CopyStr(Digits, 6, 3), CopyStr(Digits, 9, 4), CopyStr(Digits, 13, 2)));
            11:
                exit(StrSubstNo('%1.%2.%3-%4', CopyStr(Digits, 1, 3), CopyStr(Digits, 4, 3), CopyStr(Digits, 7, 3), CopyStr(Digits, 10, 2)));
        end;
        exit(Value);
    end;

    local procedure FormatPostCode(Value: Text): Text
    var
        Digits: Text;
    begin
        Digits := NFBValidation.OnlyDigits(Value);
        if StrLen(Digits) = 8 then
            exit(CopyStr(Digits, 1, 5) + '-' + CopyStr(Digits, 6, 3));
        exit(Value);
    end;

    local procedure FormatDate(Value: Date): Text
    begin
        if Value = 0D then
            exit('');
        exit(Format(Value, 0, '<Day,2>/<Month,2>/<Year4>'));
    end;

    local procedure FormatDateTime(Value: DateTime): Text
    begin
        if Value = 0DT then
            exit('');
        exit(Format(Value, 0, '<Day,2>/<Month,2>/<Year4> <Hours24,2>:<Minutes,2>:<Seconds,2>'));
    end;

    local procedure FormatAmount(Value: Decimal): Text
    begin
        exit(FormatDecimal(Value, 2));
    end;

    /// <summary>
    /// Brazilian number format (1.234,56), independent of the user's regional settings.
    /// </summary>
    local procedure FormatDecimal(Value: Decimal; Decimals: Integer): Text
    var
        Plain: Text;
        IntegerPart: Text;
        FractionPart: Text;
        Grouped: Text;
        Sign: Text;
        DotPos: Integer;
        I: Integer;
    begin
        Plain := NFBXMLBuilder.FormatDec(Value, Decimals, Decimals);
        if CopyStr(Plain, 1, 1) = '-' then begin
            Sign := '-';
            Plain := CopyStr(Plain, 2);
        end;
        DotPos := StrPos(Plain, '.');
        if DotPos > 0 then begin
            IntegerPart := CopyStr(Plain, 1, DotPos - 1);
            FractionPart := CopyStr(Plain, DotPos + 1);
        end else
            IntegerPart := Plain;
        for I := 1 to StrLen(IntegerPart) do begin
            if (I > 1) and ((StrLen(IntegerPart) - I + 1) mod 3 = 0) then
                Grouped += '.';
            Grouped += CopyStr(IntegerPart, I, 1);
        end;
        if FractionPart <> '' then
            exit(Sign + Grouped + ',' + FractionPart);
        exit(Sign + Grouped);
    end;

    local procedure JoinText(First: Text; Second: Text; Separator: Text): Text
    begin
        if First = '' then
            exit(Second);
        if Second = '' then
            exit(First);
        exit(First + Separator + Second);
    end;
}
