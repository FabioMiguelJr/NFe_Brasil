pageextension 50206 "NFB Units of Measure" extends "Units of Measure"
{
    layout
    {
        addafter(Description)
        {
            field("NFB SEFAZ Code"; Rec."NFB SEFAZ Code") { ApplicationArea = All; }
        }
    }
}
