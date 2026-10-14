table 50107 "NFB Operation Type"
{
    Caption = 'NF-e Operation Type';
    DataClassification = CustomerContent;
    DrillDownPageId = "NFB Operation Types";
    LookupPageId = "NFB Operation Types";

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Nature of Operation"; Text[60])
        {
            Caption = 'Nature of Operation (natOp)';
        }
        field(4; Direction; Enum "NFB Direction")
        {
            Caption = 'Direction (tpNF)';
            InitValue = Outbound;
        }
        field(5; Purpose; Enum "NFB Purpose")
        {
            Caption = 'Purpose (finNFe)';
            InitValue = Normal;
        }
        field(6; "Presence Indicator"; Enum "NFB Presence Indicator")
        {
            Caption = 'Buyer Presence (indPres)';
            InitValue = Other;
        }
        field(7; "CFOP Internal"; Code[4])
        {
            Caption = 'CFOP Internal';
            TableRelation = "NFB CFOP";
        }
        field(8; "CFOP Interstate"; Code[4])
        {
            Caption = 'CFOP Interstate';
            TableRelation = "NFB CFOP";
        }
        field(9; "CFOP Exterior"; Code[4])
        {
            Caption = 'CFOP Exterior';
            TableRelation = "NFB CFOP";
        }
        field(10; "Issue NF-e"; Boolean)
        {
            Caption = 'Issue NF-e';
            InitValue = true;
        }
        field(11; "Calculate Taxes"; Boolean)
        {
            Caption = 'Calculate Taxes';
            InitValue = true;
        }
        field(12; "Post Taxes"; Boolean)
        {
            Caption = 'Post Taxes';
            InitValue = true;
        }
        field(13; "Requires Reference"; Boolean)
        {
            Caption = 'Requires Referenced NF-e';
        }
        field(14; "Series"; Integer)
        {
            Caption = 'Series (blank uses default)';
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

    procedure GetCFOP(DestinationId: Enum "NFB Destination Id"): Code[4]
    begin
        case DestinationId of
            DestinationId::Internal:
                exit("CFOP Internal");
            DestinationId::Interstate:
                exit("CFOP Interstate");
            DestinationId::Exterior:
                exit("CFOP Exterior");
        end;
    end;
}
