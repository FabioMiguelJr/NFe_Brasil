page 50216 "NFB Installments Subform"
{
    PageType = ListPart;
    SourceTable = "NFB Document Installment";
    Caption = 'Installments (dup)';
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Installment No."; Rec."Installment No.") { ApplicationArea = All; }
                field("Due Date"; Rec."Due Date") { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
            }
        }
    }
}
