codeunit 50205 "NFB Access Key Mgt"
{
    // Access key layout (44 digits): cUF(2) + AAMM(4) + CNPJ(14) + mod(2) + serie(3) + nNF(9) + tpEmis(1) + cNF(8) + cDV(1)

    procedure BuildAccessKey(UFCode: Code[2]; IssueDate: Date; IssuerCNPJ: Code[14]; Model: Code[2]; Series: Integer; NFNo: Integer; EmissionType: Integer; NumericCode: Code[8]): Code[44]
    var
        KeyWithoutDV: Text;
    begin
        KeyWithoutDV :=
            PadNumber(UFCode, 2) +
            Format(IssueDate, 0, '<Year,2><Month,2>') +
            PadNumber(IssuerCNPJ, 14) +
            PadNumber(Model, 2) +
            PadNumber(Format(Series, 0, 9), 3) +
            PadNumber(Format(NFNo, 0, 9), 9) +
            Format(EmissionType, 0, 9) +
            PadNumber(NumericCode, 8);
        if StrLen(KeyWithoutDV) <> 43 then
            Error(InvalidKeyLengthErr, KeyWithoutDV);
        exit(CopyStr(KeyWithoutDV + Format(CalcCheckDigit(KeyWithoutDV), 0, 9), 1, 44));
    end;

    procedure CalcCheckDigit(Digits: Text): Integer
    var
        Weight: Integer;
        Sum: Integer;
        Digit: Integer;
        i: Integer;
        Remainder: Integer;
    begin
        // Modulo 11 with weights 2..9 from right to left (MOC 4.00, item 5.4)
        Weight := 2;
        for i := StrLen(Digits) downto 1 do begin
            Evaluate(Digit, CopyStr(Digits, i, 1));
            Sum += Digit * Weight;
            Weight += 1;
            if Weight > 9 then
                Weight := 2;
        end;
        Remainder := Sum mod 11;
        if Remainder < 2 then
            exit(0);
        exit(11 - Remainder);
    end;

    procedure GenerateNumericCode(NFNo: Integer): Code[8]
    var
        NumericCode: Code[8];
        NFNoText: Text;
    begin
        // cNF must be random and different from nNF (rejection 539/897 guidance)
        NFNoText := PadNumber(Format(NFNo, 0, 9), 8);
        repeat
            NumericCode := CopyStr(PadNumber(Format(Random(99999999), 0, 9), 8), 1, 8);
        until (NumericCode <> NFNoText) and not IsRepeatedDigits(NumericCode);
        exit(NumericCode);
    end;

    procedure ValidateAccessKey(AccessKey: Code[44]): Boolean
    var
        CheckDigit: Integer;
    begin
        if StrLen(AccessKey) <> 44 then
            exit(false);
        if DelChr(AccessKey, '=', '0123456789') <> '' then
            exit(false);
        Evaluate(CheckDigit, CopyStr(AccessKey, 44, 1));
        exit(CalcCheckDigit(CopyStr(AccessKey, 1, 43)) = CheckDigit);
    end;

    procedure PadNumber(Value: Text; Length: Integer): Text
    begin
        Value := DelChr(Value, '=', DelChr(Value, '=', '0123456789'));
        if StrLen(Value) > Length then
            Error(ValueTooLongErr, Value, Length);
        exit(PadStr('', Length - StrLen(Value), '0') + Value);
    end;

    local procedure IsRepeatedDigits(Value: Text): Boolean
    begin
        exit(DelChr(Value, '=', CopyStr(Value, 1, 1)) = '');
    end;

    var
        InvalidKeyLengthErr: Label 'The access key %1 does not have 43 digits before the check digit.', Comment = '%1 = partial key';
        ValueTooLongErr: Label 'The value %1 has more than %2 digits.', Comment = '%1 = value, %2 = length';
}
