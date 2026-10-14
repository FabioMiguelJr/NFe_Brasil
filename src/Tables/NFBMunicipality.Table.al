table 50102 "NFB Municipality"
{
    Caption = 'IBGE Municipality';
    DataClassification = CustomerContent;
    DrillDownPageId = "NFB Municipalities";
    LookupPageId = "NFB Municipalities";

    fields
    {
        field(1; Code; Code[7])
        {
            Caption = 'IBGE Code';
            Numeric = true;
            NotBlank = true;

            trigger OnValidate()
            begin
                "UF Code" := CopyStr(Code, 1, 2);
            end;
        }
        field(2; Name; Text[60])
        {
            Caption = 'Name';
        }
        field(3; UF; Code[2])
        {
            Caption = 'State (UF)';
        }
        field(4; "UF Code"; Code[2])
        {
            Caption = 'State Code (cUF)';
            Editable = false;
        }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
        key(Name; Name, UF) { }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Code, Name, UF) { }
    }
}
