tableextension 50206 "NFB Unit of Measure" extends "Unit of Measure"
{
    fields
    {
        field(50200; "NFB SEFAZ Code"; Code[6])
        {
            Caption = 'NF-e Unit Code';
            DataClassification = CustomerContent;
        }
    }
}
