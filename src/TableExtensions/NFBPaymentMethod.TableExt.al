tableextension 50208 "NFB Payment Method" extends "Payment Method"
{
    fields
    {
        field(50200; "NFB Payment Type"; Code[2])
        {
            Caption = 'NF-e Payment Type (tPag)';
            DataClassification = CustomerContent;
            Numeric = true;
        }
        field(50201; "NFB Payment Description"; Text[60])
        {
            Caption = 'NF-e Payment Description (xPag)';
            DataClassification = CustomerContent;
        }
    }
}
