codeunit 50114 "NFB XSD Validator"
{
    // Validates the NF-e XML against the SEFAZ schema package (PL_010 or later) imported in NF-e XSD Schemas.
    // The schemas are written to a server temporary folder so that their include statements resolve.

    var
        NoMainSchemaErr: Label 'No main schema is marked in NF-e XSD Schemas. Import the SEFAZ schema package and mark nfe_v4.00.xsd as the main schema.';

    procedure HasSchemas(): Boolean
    var
        NFBXSDSchema: Record "NFB XSD Schema";
    begin
        NFBXSDSchema.SetRange("Main Schema", true);
        exit(not NFBXSDSchema.IsEmpty());
    end;

    /// <summary>
    /// Validates the XML in TempBlob. An unsigned NF-e gets a placeholder signature first, because the schema requires the Signature element.
    /// Returns false and the first schema error in ErrorText when the XML is not valid.
    /// </summary>
    procedure ValidateXml(var TempBlob: Codeunit "Temp Blob"; AccessKey: Code[44]; var ErrorText: Text): Boolean
    var
        NFBXSDSchema: Record "NFB XSD Schema";
        FileManagement: Codeunit "File Management";
        SchemaBlob: Codeunit "Temp Blob";
        XmlBlob: Codeunit "Temp Blob";
        TempFolder: Text;
        MainSchemaPath: Text;
        XmlPath: Text;
        IsValid: Boolean;
    begin
        NFBXSDSchema.SetRange("Main Schema", true);
        if not NFBXSDSchema.FindFirst() then
            Error(NoMainSchemaErr);

        TempFolder := FileManagement.ServerCreateTempSubDirectory();
        NFBXSDSchema.Reset();
        NFBXSDSchema.SetAutoCalcFields(Content);
        if NFBXSDSchema.FindSet() then
            repeat
                Clear(SchemaBlob);
                SchemaBlob.FromRecord(NFBXSDSchema, NFBXSDSchema.FieldNo(Content));
                FileManagement.BLOBExportToServerFile(SchemaBlob, FileManagement.CombinePath(TempFolder, NFBXSDSchema."File Name"));
                if NFBXSDSchema."Main Schema" then
                    MainSchemaPath := FileManagement.CombinePath(TempFolder, NFBXSDSchema."File Name");
            until NFBXSDSchema.Next() = 0;

        AddPlaceholderSignature(TempBlob, XmlBlob, AccessKey);
        XmlPath := FileManagement.CombinePath(TempFolder, 'nfe-to-validate.xml');
        FileManagement.BLOBExportToServerFile(XmlBlob, XmlPath);

        ClearLastError();
        IsValid := TryValidate(XmlPath, MainSchemaPath);
        if not IsValid then
            ErrorText := GetLastErrorText();
        FileManagement.ServerRemoveDirectory(TempFolder, true);
        exit(IsValid);
    end;

    [TryFunction]
    local procedure TryValidate(XmlPath: Text; SchemaPath: Text)
    var
        XmlDoc: DotNet NFBXmlDocument;
        XmlUrlResolver: DotNet NFBXmlUrlResolver;
        XmlTextReader: DotNet NFBXmlTextReader;
        XmlSchema: DotNet NFBXmlSchema;
        ValidationEventHandler: DotNet NFBValidationEventHandler;
    begin
        // Without a ValidationEventHandler, Validate throws on the first schema error, which the TryFunction catches.
        XmlDoc := XmlDoc.XmlDocument();
        XmlUrlResolver := XmlUrlResolver.XmlUrlResolver();
        XmlDoc.Schemas.XmlResolver := XmlUrlResolver;
        XmlTextReader := XmlTextReader.XmlTextReader(SchemaPath);
        XmlSchema := XmlSchema.Read(XmlTextReader, ValidationEventHandler);
        XmlTextReader.Close();
        XmlDoc.Schemas.Add(XmlSchema);
        XmlDoc.Load(XmlPath);
        XmlDoc.Validate(ValidationEventHandler);
    end;

    local procedure AddPlaceholderSignature(var SourceBlob: Codeunit "Temp Blob"; var TargetBlob: Codeunit "Temp Blob"; AccessKey: Code[44])
    var
        InStr: InStream;
        OutStr: OutStream;
        XmlText: Text;
        Line: Text;
        LineFeed: Text[1];
    begin
        SourceBlob.CreateInStream(InStr, TextEncoding::UTF8);
        LineFeed[1] := 10;
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            XmlText += Line + LineFeed;
        end;
        if StrPos(XmlText, '<Signature') = 0 then
            XmlText := XmlText.Replace('</NFe>', PlaceholderSignature('NFe' + AccessKey) + '</NFe>');
        Clear(TargetBlob);
        TargetBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(XmlText);
    end;

    local procedure PlaceholderSignature(ReferenceId: Text): Text
    var
        Result: Text;
    begin
        Result := '<Signature xmlns="http://www.w3.org/2000/09/xmldsig#"><SignedInfo>';
        Result += '<CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"/>';
        Result += '<SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/>';
        Result += '<Reference URI="#' + ReferenceId + '"><Transforms>';
        Result += '<Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>';
        Result += '<Transform Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"/>';
        Result += '</Transforms><DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/>';
        Result += '<DigestValue>AAAAAAAAAAAAAAAAAAAAAAAAAAA=</DigestValue></Reference></SignedInfo>';
        Result += '<SignatureValue>AAAA</SignatureValue>';
        Result += '<KeyInfo><X509Data><X509Certificate>AAAA</X509Certificate></X509Data></KeyInfo></Signature>';
        exit(Result);
    end;
}
