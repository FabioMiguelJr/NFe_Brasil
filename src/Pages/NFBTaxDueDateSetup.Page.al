page 50126 "NFB Tax Due Date Setup"
{
    PageType = List;
    SourceTable = "NFB Tax Due Date Setup";
    Caption = 'NF-e Tax Due Date Setup';
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Tax Type"; Rec."Tax Type") { ApplicationArea = All; ToolTip = 'Specifies the tax.'; }
                field("State Code"; Rec."State Code") { ApplicationArea = All; }
                field("Guide Type"; Rec."Guide Type") { ApplicationArea = All; ToolTip = 'Specifies the guide used to pay the tax: DARF for federal taxes, DARJ for ICMS of RJ, GNRE for taxes owed to other states.'; }
                field("Revenue Code"; Rec."Revenue Code") { ApplicationArea = All; }
                field("Vendor No."; Rec."Vendor No.") { ApplicationArea = All; }
                field("Due Day"; Rec."Due Day") { ApplicationArea = All; }
                field("Months After Period"; Rec."Months After Period") { ApplicationArea = All; }
                field("Non-Working Day Rule"; Rec."Non-Working Day Rule") { ApplicationArea = All; }
                field("Base Calendar Code"; Rec."Base Calendar Code") { ApplicationArea = All; }
                field("Adjustment Account"; Rec."Adjustment Account") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(LoadDefaults)
            {
                ApplicationArea = All;
                Caption = 'Load Default Data';
                Image = Setup;
                ToolTip = 'Creates the default rows (guide, revenue code and due day) for ICMS, FCP, ST, DIFAL, IPI, PIS and COFINS. Existing rows are kept. The vendors must be filled in.';

                trigger OnAction()
                var
                    NFBInstall: Codeunit "NFB Install";
                begin
                    NFBInstall.InsertTaxDueDateSetup();
                end;
            }
        }
    }
}
