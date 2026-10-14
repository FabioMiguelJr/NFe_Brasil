tableextension 50123 "NFB Purch. Inv. Line" extends "Purch. Inv. Line"
{
    fields
    {
        field(50100; "NFB CFOP"; Code[4])
        {
            Caption = 'CFOP';
            DataClassification = CustomerContent;
            TableRelation = "NFB CFOP";
        }
        field(50101; "NFB Tax Rule Code"; Code[20])
        {
            Caption = 'NF-e Tax Rule';
            DataClassification = CustomerContent;
            TableRelation = "NFB Tax Rule";
        }
        field(50102; "NFB System Line"; Boolean)
        {
            Caption = 'NF-e Tax System Line';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50103; "NFB Tax Type"; Enum "NFB Tax Type")
        {
            Caption = 'NF-e Tax Type';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
