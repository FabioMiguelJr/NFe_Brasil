tableextension 50207 "NFB Country/Region" extends "Country/Region"
{
    fields
    {
        field(50200; "NFB BACEN Code"; Code[4])
        {
            Caption = 'BACEN Country Code';
            DataClassification = CustomerContent;
            Numeric = true;
        }
    }
}
