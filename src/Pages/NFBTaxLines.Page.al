page 50113 "NFB Tax Lines"
{
    PageType = List;
    SourceTable = "NFB Tax Line";
    Caption = 'NF-e Tax Lines';
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Table ID"; Rec."Table ID") { ApplicationArea = All; }
                field("Document No."; Rec."Document No.") { ApplicationArea = All; }
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field("Tax Type"; Rec."Tax Type") { ApplicationArea = All; }
                field(CST; Rec.CST) { ApplicationArea = All; }
                field("Base Amount"; Rec."Base Amount") { ApplicationArea = All; }
                field("Base Reduction %"; Rec."Base Reduction %") { ApplicationArea = All; }
                field("MVA %"; Rec."MVA %") { ApplicationArea = All; }
                field("Rate %"; Rec."Rate %") { ApplicationArea = All; }
                field("Secondary Rate %"; Rec."Secondary Rate %") { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
                field("Classification Code"; Rec."Classification Code") { ApplicationArea = All; }
                field("Tax Rule Code"; Rec."Tax Rule Code") { ApplicationArea = All; }
            }
        }
    }
}
