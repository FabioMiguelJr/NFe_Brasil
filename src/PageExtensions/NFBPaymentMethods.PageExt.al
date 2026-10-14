pageextension 50108 "NFB Payment Methods" extends "Payment Methods"
{
    layout
    {
        addafter(Description)
        {
            field("NFB Payment Type"; Rec."NFB Payment Type") { ApplicationArea = All; }
            field("NFB Payment Description"; Rec."NFB Payment Description") { ApplicationArea = All; }
        }
    }
}
