table 50118 "NFB Document File"
{
    Caption = 'NF-e Document File';
    DataClassification = CustomerContent;
    LookupPageId = "NFB Document Files";
    DrillDownPageId = "NFB Document Files";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "NFB Document Header";
        }
        field(3; "File Type"; Enum "NFB File Type")
        {
            Caption = 'File Type';
        }
        field(4; "File Name"; Text[250])
        {
            Caption = 'File Name';
        }
        field(5; Content; Blob)
        {
            Caption = 'Content';
        }
        field(6; "Created At"; DateTime)
        {
            Caption = 'Created At';
        }
        field(7; "Created By"; Code[50])
        {
            Caption = 'Created By';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(8; "Access Key"; Code[44])
        {
            Caption = 'Access Key';
        }
        field(9; "Size (Bytes)"; Integer)
        {
            Caption = 'Size (Bytes)';
        }
        field(10; "XSD Validated"; Boolean)
        {
            Caption = 'XSD Validated';
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Document; "Document No.", "File Type", "Created At") { }
    }

    trigger OnInsert()
    begin
        "Created At" := CurrentDateTime();
        "Created By" := CopyStr(UserId(), 1, MaxStrLen("Created By"));
    end;
}
