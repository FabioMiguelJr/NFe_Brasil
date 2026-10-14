table 50103 "NFB NCM"
{
    Caption = 'NCM';
    DataClassification = CustomerContent;
    DrillDownPageId = "NFB NCM List";
    LookupPageId = "NFB NCM List";

    fields
    {
        field(1; Code; Code[8])
        {
            Caption = 'NCM';
            Numeric = true;
            NotBlank = true;
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(3; CEST; Code[7])
        {
            Caption = 'CEST';
            Numeric = true;
        }
        field(4; "IPI %"; Decimal)
        {
            Caption = 'IPI %';
            DecimalPlaces = 0 : 4;
            MinValue = 0;
        }
        field(5; "Ex TIPI"; Code[3])
        {
            Caption = 'Ex TIPI';
        }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Code, Description) { }
    }
}
