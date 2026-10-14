page 50218 "NFB Transport Part"
{
    PageType = CardPart;
    SourceTable = "NFB Document Transport";
    Caption = 'Transport (transp)';

    layout
    {
        area(Content)
        {
            group(General)
            {
                ShowCaption = false;
                field("Freight Mode"; Rec."Freight Mode") { ApplicationArea = All; }
                field("Carrier CPF/CNPJ"; Rec."Carrier CPF/CNPJ") { ApplicationArea = All; }
                field("Carrier Name"; Rec."Carrier Name") { ApplicationArea = All; }
                field("Carrier IE"; Rec."Carrier IE") { ApplicationArea = All; }
                field("Carrier Address"; Rec."Carrier Address") { ApplicationArea = All; }
                field("Carrier City"; Rec."Carrier City") { ApplicationArea = All; }
                field("Carrier UF"; Rec."Carrier UF") { ApplicationArea = All; }
                field("Vehicle Plate"; Rec."Vehicle Plate") { ApplicationArea = All; }
                field("Vehicle UF"; Rec."Vehicle UF") { ApplicationArea = All; }
                field("Volume Quantity"; Rec."Volume Quantity") { ApplicationArea = All; }
                field("Volume Kind"; Rec."Volume Kind") { ApplicationArea = All; }
                field(Brand; Rec.Brand) { ApplicationArea = All; }
                field("Gross Weight"; Rec."Gross Weight") { ApplicationArea = All; }
                field("Net Weight"; Rec."Net Weight") { ApplicationArea = All; }
            }
        }
    }
}
