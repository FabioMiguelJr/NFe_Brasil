tableextension 50106 "NFB Unit of Measure" extends "Unit of Measure"
{
    fields
    {
        field(50100; "NFB SEFAZ Code"; Code[6])
        {
            Caption = 'NF-e Unit Code';
            DataClassification = CustomerContent;
        }
    }
}
