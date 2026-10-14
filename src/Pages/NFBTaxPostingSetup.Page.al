page 50208 "NFB Tax Posting Setup"
{
    PageType = List;
    SourceTable = "NFB Tax Posting Setup";
    Caption = 'NF-e Tax Posting Setup';
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Tax Type"; Rec."Tax Type") { ApplicationArea = All; }
                field("Included in Price"; Rec."Included in Price") { ApplicationArea = All; }
                field("Payable Account"; Rec."Payable Account") { ApplicationArea = All; }
                field("Sales Deduction Account"; Rec."Sales Deduction Account") { ApplicationArea = All; }
                field("Recoverable Account"; Rec."Recoverable Account") { ApplicationArea = All; }
                field("Purchase Cost Account"; Rec."Purchase Cost Account") { ApplicationArea = All; }
            }
        }
    }
}
