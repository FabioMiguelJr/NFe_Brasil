table 50213 "NFB Document Reference"
{
    Caption = 'NF-e Referenced Document (NFref)';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "NFB Document Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Referenced Access Key"; Code[44])
        {
            Caption = 'Referenced Access Key (refNFe)';
            Numeric = true;
        }
        field(4; "Referenced Document No."; Code[20])
        {
            Caption = 'Referenced NF-e';
            TableRelation = "NFB Document Header";
        }
    }

    keys
    {
        key(PK; "Document No.", "Line No.") { Clustered = true; }
    }
}
