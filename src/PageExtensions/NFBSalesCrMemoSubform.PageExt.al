pageextension 50116 "NFB Sales Cr. Memo Subform" extends "Sales Cr. Memo Subform"
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
