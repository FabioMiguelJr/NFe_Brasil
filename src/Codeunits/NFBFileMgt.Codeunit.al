codeunit 50115 "NFB File Mgt"
{
    var
        WrongStatusErr: Label 'The XML of NF-e %1 cannot be generated because its status is %2.', Comment = '%1 = document no., %2 = status';
        NotValidErr: Label 'NF-e %1 has validation errors. Use the Validate action to see them.', Comment = '%1 = document no.';
        XsdErr: Label 'The XML of NF-e %1 does not match the SEFAZ schema:\%2', Comment = '%1 = document no., %2 = schema error';
        XmlGeneratedMsg: Label 'The XML of NF-e %1 was generated and saved.', Comment = '%1 = document no.';
        NoFileErr: Label 'NF-e %1 has no XML yet. Generate it first.', Comment = '%1 = document no.';
        NothingToExportErr: Label 'None of the selected NF-e has an XML file.';
        ZipExportedMsg: Label '%1 XML file(s) were added to the ZIP file.', Comment = '%1 = number of files';
        ImportSchemaTitleTxt: Label 'Import SEFAZ schemas (.zip or .xsd)';
        SchemaFilterTxt: Label 'Schema files (*.zip;*.xsd)|*.zip;*.xsd', Locked = true;
        SchemasImportedMsg: Label '%1 schema file(s) were imported.', Comment = '%1 = number of files';
        MainSchemaFileTxt: Label 'nfe_v4.00.xsd', Locked = true;
        DownloadTitleTxt: Label 'Download NF-e file';

    /// <summary>
    /// Validates the NF-e, builds its XML, checks it against the XSD when NF-e Setup asks for it, saves it in NF-e Document Files and sets the status to XML Generated.
    /// </summary>
    procedure GenerateXml(var NFBDocumentHeader: Record "NFB Document Header"; ShowMessages: Boolean)
    var
        NFBSetup: Record "NFB Setup";
        NFBDocumentMgt: Codeunit "NFB Document Mgt";
        NFBXMLBuilder: Codeunit "NFB XML Builder";
        NFBXSDValidator: Codeunit "NFB XSD Validator";
        TempBlob: Codeunit "Temp Blob";
        ErrorText: Text;
        XsdValidated: Boolean;
    begin
        if not (NFBDocumentHeader.Status in [NFBDocumentHeader.Status::Draft, NFBDocumentHeader.Status::Validated,
            NFBDocumentHeader.Status::"XML Generated", NFBDocumentHeader.Status::Rejected])
        then
            Error(WrongStatusErr, NFBDocumentHeader."No.", NFBDocumentHeader.Status);
        if not NFBDocumentMgt.ValidateDocument(NFBDocumentHeader, false) then begin
            if ShowMessages then
                Commit();
            Error(NotValidErr, NFBDocumentHeader."No.");
        end;

        NFBXMLBuilder.BuildXml(NFBDocumentHeader, TempBlob);

        NFBSetup.Get();
        if NFBSetup."Validate XSD" then begin
            if not NFBXSDValidator.ValidateXml(TempBlob, NFBDocumentHeader."Access Key", ErrorText) then
                Error(XsdErr, NFBDocumentHeader."No.", ErrorText);
            XsdValidated := true;
        end;

        SaveFile(NFBDocumentHeader, Enum::"NFB File Type"::XML, TempBlob, NFBDocumentHeader."Access Key" + '-nfe.xml', XsdValidated);
        NFBDocumentHeader.Status := NFBDocumentHeader.Status::"XML Generated";
        NFBDocumentHeader.Modify();
        if ShowMessages then
            Message(XmlGeneratedMsg, NFBDocumentHeader."No.");
    end;

    procedure SaveFile(NFBDocumentHeader: Record "NFB Document Header"; FileType: Enum "NFB File Type"; var TempBlob: Codeunit "Temp Blob"; FileName: Text; XsdValidated: Boolean)
    var
        NFBDocumentFile: Record "NFB Document File";
        RecRef: RecordRef;
    begin
        NFBDocumentFile.Init();
        NFBDocumentFile."Document No." := NFBDocumentHeader."No.";
        NFBDocumentFile."File Type" := FileType;
        NFBDocumentFile."File Name" := CopyStr(FileName, 1, MaxStrLen(NFBDocumentFile."File Name"));
        NFBDocumentFile."Access Key" := NFBDocumentHeader."Access Key";
        NFBDocumentFile."Size (Bytes)" := TempBlob.Length();
        NFBDocumentFile."XSD Validated" := XsdValidated;
        RecRef.GetTable(NFBDocumentFile);
        TempBlob.ToRecordRef(RecRef, NFBDocumentFile.FieldNo(Content));
        RecRef.SetTable(NFBDocumentFile);
        NFBDocumentFile.Insert(true);
    end;

    /// <summary>
    /// Finds the most recent file of the document, preferring the authorized XML, then the signed XML, then the unsigned XML.
    /// </summary>
    procedure FindBestXml(DocumentNo: Code[20]; var NFBDocumentFile: Record "NFB Document File"): Boolean
    begin
        if FindLatestFile(DocumentNo, Enum::"NFB File Type"::"Authorized XML", NFBDocumentFile) then
            exit(true);
        if FindLatestFile(DocumentNo, Enum::"NFB File Type"::"Signed XML", NFBDocumentFile) then
            exit(true);
        exit(FindLatestFile(DocumentNo, Enum::"NFB File Type"::XML, NFBDocumentFile));
    end;

    procedure FindLatestFile(DocumentNo: Code[20]; FileType: Enum "NFB File Type"; var NFBDocumentFile: Record "NFB Document File"): Boolean
    begin
        NFBDocumentFile.Reset();
        NFBDocumentFile.SetCurrentKey("Document No.", "File Type", "Created At");
        NFBDocumentFile.SetRange("Document No.", DocumentNo);
        NFBDocumentFile.SetRange("File Type", FileType);
        exit(NFBDocumentFile.FindLast());
    end;

    procedure DownloadXml(NFBDocumentHeader: Record "NFB Document Header")
    var
        NFBDocumentFile: Record "NFB Document File";
    begin
        if not FindBestXml(NFBDocumentHeader."No.", NFBDocumentFile) then
            Error(NoFileErr, NFBDocumentHeader."No.");
        DownloadFile(NFBDocumentFile);
    end;

    procedure DownloadFile(var NFBDocumentFile: Record "NFB Document File")
    var
        InStr: InStream;
        FileName: Text;
    begin
        NFBDocumentFile.CalcFields(Content);
        NFBDocumentFile.Content.CreateInStream(InStr);
        FileName := NFBDocumentFile."File Name";
        DownloadFromStream(InStr, DownloadTitleTxt, '', '', FileName);
    end;

    /// <summary>
    /// Puts the best XML of each document in the filter into one ZIP file and downloads it.
    /// </summary>
    procedure ExportZip(var NFBDocumentHeader: Record "NFB Document Header"; ZipFileName: Text; ShowMessages: Boolean)
    var
        NFBDocumentFile: Record "NFB Document File";
        DataCompression: Codeunit "Data Compression";
        ZipBlob: Codeunit "Temp Blob";
        InStr: InStream;
        FileCount: Integer;
    begin
        DataCompression.CreateZipArchive();
        if NFBDocumentHeader.FindSet() then
            repeat
                if FindBestXml(NFBDocumentHeader."No.", NFBDocumentFile) then begin
                    NFBDocumentFile.CalcFields(Content);
                    NFBDocumentFile.Content.CreateInStream(InStr);
                    DataCompression.AddEntry(InStr, NFBDocumentFile."File Name");
                    FileCount += 1;
                end;
            until NFBDocumentHeader.Next() = 0;
        if FileCount = 0 then begin
            DataCompression.CloseZipArchive();
            Error(NothingToExportErr);
        end;
        DataCompression.SaveZipArchive(ZipBlob);
        DataCompression.CloseZipArchive();
        ZipBlob.CreateInStream(InStr);
        DownloadFromStream(InStr, DownloadTitleTxt, '', '', ZipFileName);
        if ShowMessages then
            Message(ZipExportedMsg, FileCount);
    end;

    /// <summary>
    /// Imports the SEFAZ schema package. Accepts the .zip published on the NF-e portal or a single .xsd file.
    /// </summary>
    procedure ImportSchemas()
    var
        DataCompression: Codeunit "Data Compression";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        EntryList: List of [Text];
        EntryName: Text;
        FromFile: Text;
        ImportedCount: Integer;
    begin
        if not UploadIntoStream(ImportSchemaTitleTxt, '', SchemaFilterTxt, FromFile, InStr) then
            exit;
        if LowerCase(FromFile).EndsWith('.zip') then begin
            DataCompression.OpenZipArchive(InStr, false);
            DataCompression.GetEntryList(EntryList);
            foreach EntryName in EntryList do
                if LowerCase(EntryName).EndsWith('.xsd') then begin
                    Clear(TempBlob);
                    DataCompression.ExtractEntry(EntryName, TempBlob);
                    SaveSchema(GetFileName(EntryName), TempBlob);
                    ImportedCount += 1;
                end;
            DataCompression.CloseZipArchive();
        end else begin
            CopyStreamToBlob(InStr, TempBlob);
            SaveSchema(GetFileName(FromFile), TempBlob);
            ImportedCount := 1;
        end;
        Message(SchemasImportedMsg, ImportedCount);
    end;

    local procedure SaveSchema(FileName: Text; var TempBlob: Codeunit "Temp Blob")
    var
        NFBXSDSchema: Record "NFB XSD Schema";
        RecRef: RecordRef;
        IsNew: Boolean;
    begin
        FileName := CopyStr(FileName, 1, MaxStrLen(NFBXSDSchema."File Name"));
        IsNew := not NFBXSDSchema.Get(FileName);
        if IsNew then begin
            NFBXSDSchema.Init();
            NFBXSDSchema."File Name" := CopyStr(FileName, 1, MaxStrLen(NFBXSDSchema."File Name"));
            NFBXSDSchema."Main Schema" := LowerCase(FileName) = MainSchemaFileTxt;
        end;
        NFBXSDSchema."Imported At" := CurrentDateTime();
        NFBXSDSchema."Size (Bytes)" := TempBlob.Length();
        RecRef.GetTable(NFBXSDSchema);
        TempBlob.ToRecordRef(RecRef, NFBXSDSchema.FieldNo(Content));
        RecRef.SetTable(NFBXSDSchema);
        if IsNew then
            NFBXSDSchema.Insert()
        else
            NFBXSDSchema.Modify();
    end;

    local procedure CopyStreamToBlob(var InStr: InStream; var TempBlob: Codeunit "Temp Blob")
    var
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);
    end;

    local procedure GetFileName(Path: Text): Text
    var
        Position: Integer;
    begin
        Path := Path.Replace('\', '/');
        Position := Path.LastIndexOf('/');
        if Position > 0 then
            exit(CopyStr(Path, Position + 1));
        exit(Path);
    end;
}
