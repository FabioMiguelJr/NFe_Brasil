page 50112 "NFB Payments Subform"
{
    PageType = ListPart;
    SourceTable = "NFB Document Payment";
    Caption = 'Payments (detPag)';
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Payment Indicator"; Rec."Payment Indicator") { ApplicationArea = All; }
                field("Payment Type"; Rec."Payment Type") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
                field(Change; Rec.Change) { ApplicationArea = All; }
                field("Card Integration"; Rec."Card Integration") { ApplicationArea = All; }
                field("Card Acquirer CNPJ"; Rec."Card Acquirer CNPJ") { ApplicationArea = All; }
                field("Card Brand"; Rec."Card Brand") { ApplicationArea = All; }
                field("Card Authorization"; Rec."Card Authorization") { ApplicationArea = All; }
            }
        }
    }
}
