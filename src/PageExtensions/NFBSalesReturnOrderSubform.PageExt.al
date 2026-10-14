pageextension 50133 "NFB Sales Return Ord. Subform" extends "Sales Return Order Subform"
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
