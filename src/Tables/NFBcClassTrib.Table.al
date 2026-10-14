table 50205 "NFB cClassTrib"
{
    Caption = 'IBS/CBS Tax Classification (cClassTrib)';
    DataClassification = CustomerContent;
    DrillDownPageId = "NFB cClassTrib List";
    LookupPageId = "NFB cClassTrib List";

    fields
    {
        field(1; Code; Code[6])
        {
            Caption = 'cClassTrib';
            Numeric = true;
            NotBlank = true;
        }
        field(2; CST; Code[3])
        {
            Caption = 'IBS/CBS CST';
            Numeric = true;
        }
        field(3; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(4; "IBS Reduction %"; Decimal)
        {
            Caption = 'IBS Rate Reduction %';
            DecimalPlaces = 0 : 4;
            MinValue = 0;
            MaxValue = 100;
        }
        field(5; "CBS Reduction %"; Decimal)
        {
            Caption = 'CBS Rate Reduction %';
            DecimalPlaces = 0 : 4;
            MinValue = 0;
            MaxValue = 100;
        }
        field(6; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(7; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
        }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Code, CST, Description) { }
    }
}
