page 50123 "NFB Tax Settlements"
{
    PageType = List;
    SourceTable = "NFB Tax Settlement Header";
    Caption = 'NF-e Tax Settlements';
    ApplicationArea = All;
    UsageCategory = Tasks;
    CardPageId = "NFB Tax Settlement";
    Editable = false;
    SourceTableView = sorting("Starting Date") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Settlements)
            {
                field("No."; Rec."No.") { ApplicationArea = All; ToolTip = 'Specifies the number of the settlement.'; }
                field(Description; Rec.Description) { ApplicationArea = All; ToolTip = 'Specifies the description of the settlement.'; }
                field("Starting Date"; Rec."Starting Date") { ApplicationArea = All; }
                field("Ending Date"; Rec."Ending Date") { ApplicationArea = All; ToolTip = 'Specifies the last day of the settled month.'; }
                field(Status; Rec.Status) { ApplicationArea = All; ToolTip = 'Specifies whether the settlement is open or posted.'; }
                field("Total Payable"; Rec."Total Payable") { ApplicationArea = All; ToolTip = 'Specifies the total of the guides of the settlement.'; }
                field("Total Credit Carried Forward"; Rec."Total Credit Carried Forward") { ApplicationArea = All; ToolTip = 'Specifies the total credit carried to the next settlement.'; }
                field("Posted At"; Rec."Posted At") { ApplicationArea = All; ToolTip = 'Specifies when the settlement was posted.'; }
            }
        }
    }

    actions
    {
        area(Reporting)
        {
            action(PrintSettlement)
            {
                ApplicationArea = All;
                Caption = 'Tax Settlement Report';
                Image = Report;
                ToolTip = 'Prints the settlements by period, one line per tax.';
                RunObject = report "NFB Tax Settlement";
            }
        }
        area(Navigation)
        {
            action(DueDateSetup)
            {
                ApplicationArea = All;
                Caption = 'Tax Due Date Setup';
                Image = DueDate;
                ToolTip = 'Opens the guide, vendor and due date of each tax.';
                RunObject = page "NFB Tax Due Date Setup";
            }
        }
    }
}
