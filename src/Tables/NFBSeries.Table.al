table 50201 "NFB Series"
{
    Caption = 'NF-e Series';
    DataClassification = CustomerContent;
    DrillDownPageId = "NFB Series";
    LookupPageId = "NFB Series";

    fields
    {
        field(1; Model; Code[2])
        {
            Caption = 'Model';
            InitValue = '55';
        }
        field(2; Series; Integer)
        {
            Caption = 'Series';
            MinValue = 0;
            MaxValue = 999;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(5; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
    }

    keys
    {
        key(PK; Model, Series) { Clustered = true; }
    }
}
