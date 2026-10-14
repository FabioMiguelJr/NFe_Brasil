codeunit 50204 "NFB Validation"
{
    procedure OnlyDigits(Value: Text): Text
    begin
        exit(DelChr(Value, '=', DelChr(Value, '=', '0123456789')));
    end;

    procedure CheckCpfCnpj(Value: Text)
    begin
        Value := OnlyDigits(Value);
        case StrLen(Value) of
            11:
                if not IsValidCpf(Value) then
                    Error(InvalidCpfErr, Value);
            14:
                if not IsValidCnpj(Value) then
                    Error(InvalidCnpjErr, Value);
            else
                Error(InvalidLengthErr, Value);
        end;
    end;

    procedure IsValidCpf(Cpf: Text): Boolean
    var
        Digits: array[11] of Integer;
        i: Integer;
        Sum: Integer;
        Check: Integer;
    begin
        Cpf := OnlyDigits(Cpf);
        if StrLen(Cpf) <> 11 then
            exit(false);
        if DelChr(Cpf, '=', CopyStr(Cpf, 1, 1)) = '' then
            exit(false);
        for i := 1 to 11 do
            Evaluate(Digits[i], CopyStr(Cpf, i, 1));

        Sum := 0;
        for i := 1 to 9 do
            Sum += Digits[i] * (11 - i);
        Check := (Sum * 10) mod 11;
        if Check = 10 then
            Check := 0;
        if Check <> Digits[10] then
            exit(false);

        Sum := 0;
        for i := 1 to 10 do
            Sum += Digits[i] * (12 - i);
        Check := (Sum * 10) mod 11;
        if Check = 10 then
            Check := 0;
        exit(Check = Digits[11]);
    end;

    procedure IsValidCnpj(Cnpj: Text): Boolean
    var
        Digits: array[14] of Integer;
        Weights1: Text;
        Weights2: Text;
        i: Integer;
        Weight: Integer;
        Sum: Integer;
        Check: Integer;
    begin
        Cnpj := OnlyDigits(Cnpj);
        if StrLen(Cnpj) <> 14 then
            exit(false);
        if DelChr(Cnpj, '=', CopyStr(Cnpj, 1, 1)) = '' then
            exit(false);
        for i := 1 to 14 do
            Evaluate(Digits[i], CopyStr(Cnpj, i, 1));

        Weights1 := '543298765432';
        Weights2 := '6543298765432';

        Sum := 0;
        for i := 1 to 12 do begin
            Evaluate(Weight, CopyStr(Weights1, i, 1));
            Sum += Digits[i] * Weight;
        end;
        Check := Sum mod 11;
        if Check < 2 then
            Check := 0
        else
            Check := 11 - Check;
        if Check <> Digits[13] then
            exit(false);

        Sum := 0;
        for i := 1 to 13 do begin
            Evaluate(Weight, CopyStr(Weights2, i, 1));
            Sum += Digits[i] * Weight;
        end;
        Check := Sum mod 11;
        if Check < 2 then
            Check := 0
        else
            Check := 11 - Check;
        exit(Check = Digits[14]);
    end;

    procedure ValidateDocument(var NFBDocumentHeader: Record "NFB Document Header"; var TempErrorMessage: Record "Error Message" temporary): Boolean
    var
        NFBDocumentLine: Record "NFB Document Line";
        NFBDocumentPayment: Record "NFB Document Payment";
        NFBDocumentReference: Record "NFB Document Reference";
        NFBOperationType: Record "NFB Operation Type";
        NFBCFOP: Record "NFB CFOP";
        TotalPayments: Decimal;
        HasNoPaymentType: Boolean;
    begin
        TempErrorMessage.ClearLog();

        // Issuer
        if not IsValidCnpj(NFBDocumentHeader."Issuer CNPJ") then
            LogError(TempErrorMessage, StrSubstNo(IssuerCnpjErr, NFBDocumentHeader."Issuer CNPJ"));
        if NFBDocumentHeader."Issuer IE" = '' then
            LogError(TempErrorMessage, IssuerIeErr);
        if (NFBDocumentHeader."Issuer UF" = '') or (NFBDocumentHeader."Issuer UF Code" = '') or (NFBDocumentHeader."Taxable Event Municipality" = '') then
            LogError(TempErrorMessage, IssuerAddressErr);

        // Recipient
        if NFBDocumentHeader."Recipient Name" = '' then
            LogError(TempErrorMessage, RecipientNameErr);
        case NFBDocumentHeader."Recipient Type" of
            NFBDocumentHeader."Recipient Type"::"Legal Entity":
                if not IsValidCnpj(NFBDocumentHeader."Recipient CPF/CNPJ") then
                    LogError(TempErrorMessage, StrSubstNo(RecipientDocErr, NFBDocumentHeader."Recipient CPF/CNPJ"));
            NFBDocumentHeader."Recipient Type"::"Natural Person":
                if not IsValidCpf(NFBDocumentHeader."Recipient CPF/CNPJ") then
                    LogError(TempErrorMessage, StrSubstNo(RecipientDocErr, NFBDocumentHeader."Recipient CPF/CNPJ"));
        end;
        if NFBDocumentHeader."Recipient Type" <> NFBDocumentHeader."Recipient Type"::Foreign then begin
            if (NFBDocumentHeader."Recipient Municipality Code" = '') or (NFBDocumentHeader."Recipient UF" = '') then
                LogError(TempErrorMessage, RecipientAddressErr);
            if NFBDocumentHeader."Recipient Address" = '' then
                LogError(TempErrorMessage, RecipientAddressErr);
        end;
        if (NFBDocumentHeader."Recipient IE Indicator" = NFBDocumentHeader."Recipient IE Indicator"::Contributor) and (NFBDocumentHeader."Recipient IE" = '') then
            LogError(TempErrorMessage, RecipientIeErr);
        if (NFBDocumentHeader."Recipient IE Indicator" = NFBDocumentHeader."Recipient IE Indicator"::"Non-Contributor") and
           (NFBDocumentHeader.Direction = NFBDocumentHeader.Direction::Outbound) and
           (NFBDocumentHeader.Purpose = NFBDocumentHeader.Purpose::Normal) and
           not NFBDocumentHeader."Final Consumer"
        then
            LogError(TempErrorMessage, NonContributorFinalErr);

        // Lines
        NFBDocumentLine.SetRange("Document No.", NFBDocumentHeader."No.");
        if NFBDocumentLine.IsEmpty() then
            LogError(TempErrorMessage, NoLinesErr);
        if NFBDocumentLine.FindSet() then
            repeat
                if StrLen(NFBDocumentLine.NCM) <> 8 then
                    LogError(TempErrorMessage, StrSubstNo(LineNcmErr, NFBDocumentLine."Item Seq.", NFBDocumentLine."Product Code"));
                if not NFBCFOP.Get(NFBDocumentLine.CFOP) then
                    LogError(TempErrorMessage, StrSubstNo(LineCfopErr, NFBDocumentLine."Item Seq.", NFBDocumentLine.CFOP))
                else
                    if (NFBCFOP.Direction <> NFBDocumentHeader.Direction) or (NFBCFOP.Destination <> NFBDocumentHeader."Destination Id") then
                        LogError(TempErrorMessage, StrSubstNo(LineCfopDestErr, NFBDocumentLine."Item Seq.", NFBDocumentLine.CFOP, NFBDocumentHeader.Direction, NFBDocumentHeader."Destination Id"));
                if NFBDocumentLine."Commercial Quantity" <= 0 then
                    LogError(TempErrorMessage, StrSubstNo(LineQtyErr, NFBDocumentLine."Item Seq."));
                if (NFBDocumentLine."Commercial Unit" = '') or (NFBDocumentLine."Taxable Unit" = '') then
                    LogError(TempErrorMessage, StrSubstNo(LineUnitErr, NFBDocumentLine."Item Seq."));
                if NFBDocumentLine."ICMS CST" = '' then
                    LogError(TempErrorMessage, StrSubstNo(LineCstErr, NFBDocumentLine."Item Seq.", 'ICMS'));
                if (NFBDocumentLine."PIS CST" = '') or (NFBDocumentLine."COFINS CST" = '') then
                    LogError(TempErrorMessage, StrSubstNo(LineCstErr, NFBDocumentLine."Item Seq.", 'PIS/COFINS'));
            until NFBDocumentLine.Next() = 0;

        // Payments
        NFBDocumentPayment.SetRange("Document No.", NFBDocumentHeader."No.");
        if NFBDocumentPayment.IsEmpty() then
            LogError(TempErrorMessage, NoPaymentErr);
        if NFBDocumentPayment.FindSet() then
            repeat
                if NFBDocumentPayment."Payment Type" = '90' then
                    HasNoPaymentType := true;
                TotalPayments += NFBDocumentPayment.Amount - NFBDocumentPayment.Change;
            until NFBDocumentPayment.Next() = 0;
        if (not HasNoPaymentType) and (TotalPayments <> NFBDocumentHeader."Invoice Amount") then
            LogError(TempErrorMessage, StrSubstNo(PaymentTotalErr, TotalPayments, NFBDocumentHeader."Invoice Amount"));

        // References
        NFBDocumentReference.SetRange("Document No.", NFBDocumentHeader."No.");
        if NFBOperationType.Get(NFBDocumentHeader."Operation Type") then
            if (NFBOperationType."Requires Reference" or (NFBDocumentHeader.Purpose = NFBDocumentHeader.Purpose::Return)) and NFBDocumentReference.IsEmpty() then
                LogError(TempErrorMessage, ReferenceErr);

        exit(not TempErrorMessage.HasErrors(false));
    end;

    local procedure LogError(var TempErrorMessage: Record "Error Message" temporary; Description: Text)
    begin
        TempErrorMessage.LogSimpleMessage(TempErrorMessage."Message Type"::Error, Description);
    end;

    var
        InvalidCpfErr: Label 'CPF %1 is not valid.', Comment = '%1 = CPF';
        InvalidCnpjErr: Label 'CNPJ %1 is not valid.', Comment = '%1 = CNPJ';
        InvalidLengthErr: Label '%1 must have 11 digits (CPF) or 14 digits (CNPJ).', Comment = '%1 = value';
        IssuerCnpjErr: Label 'Issuer CNPJ %1 is not valid. Check Company Information.', Comment = '%1 = CNPJ';
        IssuerIeErr: Label 'Issuer state registration (IE) is missing. Check Company Information.';
        IssuerAddressErr: Label 'Issuer municipality (IBGE) and state are required. Check Company Information or the location.';
        RecipientNameErr: Label 'Recipient name is missing.';
        RecipientDocErr: Label 'Recipient CPF/CNPJ %1 is not valid.', Comment = '%1 = CPF or CNPJ';
        RecipientAddressErr: Label 'Recipient street, municipality (IBGE) and state are required.';
        RecipientIeErr: Label 'Recipient is an ICMS contributor but has no state registration (IE).';
        NonContributorFinalErr: Label 'A sale to a non-contributor recipient must be marked as final consumer (indFinal = 1).';
        NoLinesErr: Label 'The NF-e has no lines.';
        LineNcmErr: Label 'Item %1 (%2): NCM must have 8 digits.', Comment = '%1 = nItem, %2 = product code';
        LineCfopErr: Label 'Item %1: CFOP %2 does not exist.', Comment = '%1 = nItem, %2 = CFOP';
        LineCfopDestErr: Label 'Item %1: CFOP %2 does not match direction %3 and destination %4.', Comment = '%1 = nItem, %2 = CFOP, %3 = direction, %4 = destination';
        LineQtyErr: Label 'Item %1: quantity must be greater than zero.', Comment = '%1 = nItem';
        LineUnitErr: Label 'Item %1: commercial and taxable units are required.', Comment = '%1 = nItem';
        LineCstErr: Label 'Item %1: %2 CST is missing. Check the tax rule.', Comment = '%1 = nItem, %2 = tax name';
        NoPaymentErr: Label 'The NF-e has no payment group (detPag).';
        PaymentTotalErr: Label 'Payments total %1 differs from the NF-e total %2.', Comment = '%1 = payments, %2 = vNF';
        ReferenceErr: Label 'This operation requires a referenced NF-e (NFref).';
}
