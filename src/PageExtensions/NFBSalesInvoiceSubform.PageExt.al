pageextension 50215 "NFB Sales Invoice Subform" extends "Sales Invoice Subform"
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
