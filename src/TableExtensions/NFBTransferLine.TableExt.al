tableextension 50117 "NFB Transfer Line" extends "Transfer Line"
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
    }
}
