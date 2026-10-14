table 50119 "NFB XSD Schema"
{
    Caption = 'NF-e XSD Schema';
    DataClassification = SystemMetadata;
    LookupPageId = "NFB XSD Schemas";
    DrillDownPageId = "NFB XSD Schemas";

    fields
    {
        field(1; "File Name"; Text[100])
        {
            Caption = 'File Name';
        }
        field(2; "Main Schema"; Boolean)
        {
            Caption = 'Main Schema';
            ToolTip = 'Specifies the schema the NF-e is validated against (nfe_v4.00.xsd). The other files are loaded through its include statements.';
        }
        field(3; Content; Blob)
        {
            Caption = 'Content';
        }
        field(4; "Imported At"; DateTime)
        {
            Caption = 'Imported At';
        }
        field(5; "Size (Bytes)"; Integer)
        {
            Caption = 'Size (Bytes)';
        }
    }

    keys
    {
        key(PK; "File Name") { Clustered = true; }
    }
}
