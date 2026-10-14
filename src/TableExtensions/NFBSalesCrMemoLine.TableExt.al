tableextension 50222 "NFB Sales Cr.Memo Line" extends "Sales Cr.Memo Line"
{
    fields
    {
        field(50200; "NFB CFOP"; Code[4])
        {
            Caption = 'CFOP';
            DataClassification = CustomerContent;
            TableRelation = "NFB CFOP";
        }
        field(50201; "NFB Tax Rule Code"; Code[20])
        {
            Caption = 'NF-e Tax Rule';
            DataClassification = CustomerContent;
            TableRelation = "NFB Tax Rule";
        }
        field(50202; "NFB System Line"; Boolean)
        {
            Caption = 'NF-e Tax System Line';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50203; "NFB Tax Type"; Enum "NFB Tax Type")
        {
            Caption = 'NF-e Tax Type';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
