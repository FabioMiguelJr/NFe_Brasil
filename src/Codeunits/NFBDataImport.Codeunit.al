codeunit 50106 "NFB Data Import"
{
    // Imports reference tables from semicolon-separated files with a header row.
    // Municipalities: IBGE code;name;UF
    // NCM:            NCM;description;CEST;IPI %;Ex TIPI
    // CFOP:           CFOP;description;is return (0/1)
    // cClassTrib:     cClassTrib;CST;description;IBS reduction %;CBS reduction %

    var
        SelectFileTxt: Label 'Select the CSV file';
        ImportedMsg: Label '%1 records imported.', Comment = '%1 = count';

    procedure ImportMunicipalities()
    var
        NFBMunicipality: Record "NFB Municipality";
        TempCSVBuffer: Record "CSV Buffer" temporary;
        LineNo: Integer;
        ImportedCount: Integer;
    begin
        if not LoadFile(TempCSVBuffer) then
            exit;
        for LineNo := 2 to TempCSVBuffer.GetNumberOfLines() do begin
            NFBMunicipality.Init();
            NFBMunicipality.Validate(Code, CopyStr(TempCSVBuffer.GetValue(LineNo, 1), 1, MaxStrLen(NFBMunicipality.Code)));
            NFBMunicipality.Name := CopyStr(TempCSVBuffer.GetValue(LineNo, 2), 1, MaxStrLen(NFBMunicipality.Name));
            NFBMunicipality.UF := CopyStr(TempCSVBuffer.GetValue(LineNo, 3), 1, MaxStrLen(NFBMunicipality.UF));
            if not NFBMunicipality.Insert() then
                NFBMunicipality.Modify();
            ImportedCount += 1;
        end;
        Message(ImportedMsg, ImportedCount);
    end;

    procedure ImportNCM()
    var
        NFBNCM: Record "NFB NCM";
        TempCSVBuffer: Record "CSV Buffer" temporary;
        LineNo: Integer;
        ImportedCount: Integer;
    begin
        if not LoadFile(TempCSVBuffer) then
            exit;
        for LineNo := 2 to TempCSVBuffer.GetNumberOfLines() do begin
            NFBNCM.Init();
            NFBNCM.Code := CopyStr(OnlyDigits(TempCSVBuffer.GetValue(LineNo, 1)), 1, MaxStrLen(NFBNCM.Code));
            NFBNCM.Description := CopyStr(TempCSVBuffer.GetValue(LineNo, 2), 1, MaxStrLen(NFBNCM.Description));
            NFBNCM.CEST := CopyStr(OnlyDigits(TempCSVBuffer.GetValue(LineNo, 3)), 1, MaxStrLen(NFBNCM.CEST));
            NFBNCM."IPI %" := ToDecimal(TempCSVBuffer.GetValue(LineNo, 4));
            NFBNCM."Ex TIPI" := CopyStr(TempCSVBuffer.GetValue(LineNo, 5), 1, MaxStrLen(NFBNCM."Ex TIPI"));
            if NFBNCM.Code <> '' then begin
                if not NFBNCM.Insert() then
                    NFBNCM.Modify();
                ImportedCount += 1;
            end;
        end;
        Message(ImportedMsg, ImportedCount);
    end;

    procedure ImportCFOP()
    var
        NFBCFOP: Record "NFB CFOP";
        TempCSVBuffer: Record "CSV Buffer" temporary;
        LineNo: Integer;
        ImportedCount: Integer;
    begin
        if not LoadFile(TempCSVBuffer) then
            exit;
        for LineNo := 2 to TempCSVBuffer.GetNumberOfLines() do begin
            NFBCFOP.Init();
            NFBCFOP.Validate(Code, CopyStr(OnlyDigits(TempCSVBuffer.GetValue(LineNo, 1)), 1, MaxStrLen(NFBCFOP.Code)));
            NFBCFOP.Description := CopyStr(TempCSVBuffer.GetValue(LineNo, 2), 1, MaxStrLen(NFBCFOP.Description));
            NFBCFOP."Is Return" := TempCSVBuffer.GetValue(LineNo, 3) = '1';
            if not NFBCFOP.Insert() then
                NFBCFOP.Modify();
            ImportedCount += 1;
        end;
        Message(ImportedMsg, ImportedCount);
    end;

    procedure ImportcClassTrib()
    var
        NFBcClassTrib: Record "NFB cClassTrib";
        TempCSVBuffer: Record "CSV Buffer" temporary;
        LineNo: Integer;
        ImportedCount: Integer;
    begin
        if not LoadFile(TempCSVBuffer) then
            exit;
        for LineNo := 2 to TempCSVBuffer.GetNumberOfLines() do begin
            NFBcClassTrib.Init();
            NFBcClassTrib.Code := CopyStr(OnlyDigits(TempCSVBuffer.GetValue(LineNo, 1)), 1, MaxStrLen(NFBcClassTrib.Code));
            NFBcClassTrib.CST := CopyStr(OnlyDigits(TempCSVBuffer.GetValue(LineNo, 2)), 1, MaxStrLen(NFBcClassTrib.CST));
            NFBcClassTrib.Description := CopyStr(TempCSVBuffer.GetValue(LineNo, 3), 1, MaxStrLen(NFBcClassTrib.Description));
            NFBcClassTrib."IBS Reduction %" := ToDecimal(TempCSVBuffer.GetValue(LineNo, 4));
            NFBcClassTrib."CBS Reduction %" := ToDecimal(TempCSVBuffer.GetValue(LineNo, 5));
            if NFBcClassTrib.Code <> '' then begin
                if not NFBcClassTrib.Insert() then
                    NFBcClassTrib.Modify();
                ImportedCount += 1;
            end;
        end;
        Message(ImportedMsg, ImportedCount);
    end;

    local procedure LoadFile(var TempCSVBuffer: Record "CSV Buffer" temporary): Boolean
    var
        FileInStream: InStream;
        FileName: Text;
    begin
        if not UploadIntoStream(SelectFileTxt, '', 'CSV (*.csv)|*.csv|Text (*.txt)|*.txt', FileName, FileInStream) then
            exit(false);
        TempCSVBuffer.LoadDataFromStream(FileInStream, ';');
        exit(true);
    end;

    local procedure OnlyDigits(Value: Text): Text
    begin
        exit(DelChr(Value, '=', DelChr(Value, '=', '0123456789')));
    end;

    local procedure ToDecimal(Value: Text): Decimal
    var
        Result: Decimal;
    begin
        Value := ConvertStr(DelChr(Value, '=', ' '), ',', '.');
        if Value = '' then
            exit(0);
        if not Evaluate(Result, Value, 9) then
            exit(0);
        exit(Result);
    end;
}
