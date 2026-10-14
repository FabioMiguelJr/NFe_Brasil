pageextension 50131 "NFB Transfer Order Subform" extends "Transfer Order Subform"
{
    layout
    {
        addafter(Description)
        {
            field("NFB CFOP"; Rec."NFB CFOP") { ApplicationArea = All; }
            field("NFB Tax Rule Code"; Rec."NFB Tax Rule Code") { ApplicationArea = All; }
        }
    }
}
