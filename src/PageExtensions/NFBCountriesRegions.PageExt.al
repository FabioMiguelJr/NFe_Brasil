pageextension 50107 "NFB Countries/Regions" extends "Countries/Regions"
{
    layout
    {
        addafter(Name)
        {
            field("NFB BACEN Code"; Rec."NFB BACEN Code") { ApplicationArea = All; }
        }
    }
}
