table 50104 "NFB CFOP"
{
    Caption = 'CFOP';
    DataClassification = CustomerContent;
    DrillDownPageId = "NFB CFOP List";
    LookupPageId = "NFB CFOP List";

    fields
    {
        field(1; Code; Code[4])
        {
            Caption = 'CFOP';
            Numeric = true;
            NotBlank = true;

            trigger OnValidate()
            begin
                if StrLen(Code) <> 4 then
                    Error(InvalidCfopErr, Code);
                case CopyStr(Code, 1, 1) of
                    '1', '2', '3':
                        Direction := Direction::Inbound;
                    '5', '6', '7':
                        Direction := Direction::Outbound;
                    else
                        Error(InvalidCfopErr, Code);
                end;
                case CopyStr(Code, 1, 1) of
                    '1', '5':
                        Destination := Destination::Internal;
                    '2', '6':
                        Destination := Destination::Interstate;
                    '3', '7':
                        Destination := Destination::Exterior;
                end;
            end;
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(3; Direction; Enum "NFB Direction")
        {
            Caption = 'Direction';
            Editable = false;
        }
        field(4; Destination; Enum "NFB Destination Id")
        {
            Caption = 'Destination';
            Editable = false;
        }
        field(5; "Is Return"; Boolean)
        {
            Caption = 'Is Return';
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

    var
        InvalidCfopErr: Label 'CFOP %1 is not valid. It must have 4 digits and start with 1, 2, 3, 5, 6 or 7.', Comment = '%1 = CFOP';
}
