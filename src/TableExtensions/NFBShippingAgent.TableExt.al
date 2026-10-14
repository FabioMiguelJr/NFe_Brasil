tableextension 50104 "NFB Shipping Agent" extends "Shipping Agent"
{
    fields
    {
        field(50100; "NFB Vendor No."; Code[20])
        {
            Caption = 'Carrier Vendor No.';
            DataClassification = CustomerContent;
            TableRelation = Vendor;
        }
        field(50101; "NFB Vehicle Plate"; Code[8])
        {
            Caption = 'Vehicle Plate';
            DataClassification = CustomerContent;
        }
        field(50102; "NFB Vehicle UF"; Code[2])
        {
            Caption = 'Vehicle State (UF)';
            DataClassification = CustomerContent;
        }
    }
}
