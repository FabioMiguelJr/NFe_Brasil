tableextension 50204 "NFB Shipping Agent" extends "Shipping Agent"
{
    fields
    {
        field(50200; "NFB Vendor No."; Code[20])
        {
            Caption = 'Carrier Vendor No.';
            DataClassification = CustomerContent;
            TableRelation = Vendor;
        }
        field(50201; "NFB Vehicle Plate"; Code[8])
        {
            Caption = 'Vehicle Plate';
            DataClassification = CustomerContent;
        }
        field(50202; "NFB Vehicle UF"; Code[2])
        {
            Caption = 'Vehicle State (UF)';
            DataClassification = CustomerContent;
        }
    }
}
