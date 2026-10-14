pageextension 50204 "NFB Shipping Agents" extends "Shipping Agents"
{
    layout
    {
        addafter(Name)
        {
            field("NFB Vendor No."; Rec."NFB Vendor No.") { ApplicationArea = All; }
            field("NFB Vehicle Plate"; Rec."NFB Vehicle Plate") { ApplicationArea = All; }
            field("NFB Vehicle UF"; Rec."NFB Vehicle UF") { ApplicationArea = All; }
        }
    }
}
