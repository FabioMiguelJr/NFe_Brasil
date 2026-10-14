page 50125 "NFB Tax Settlement Subform"
{
    PageType = ListPart;
    SourceTable = "NFB Tax Settlement Line";
    Caption = 'Taxes';
    AutoSplitKey = false;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Tax Type"; Rec."Tax Type") { ApplicationArea = All; ToolTip = 'Specifies the tax settled on the line.'; }
                field("State Code"; Rec."State Code") { ApplicationArea = All; }
                field("Output Tax"; Rec."Output Tax")
                {
                    ApplicationArea = All;

                    trigger OnDrillDown()
                    begin
                        Rec.ShowEntries();
                    end;
                }
                field("Input Tax"; Rec."Input Tax")
                {
                    ApplicationArea = All;

                    trigger OnDrillDown()
                    begin
                        Rec.ShowEntries();
                    end;
                }
                field("Other Debits"; Rec."Other Debits") { ApplicationArea = All; }
                field("Other Credits"; Rec."Other Credits") { ApplicationArea = All; }
                field("Previous Credit Balance"; Rec."Previous Credit Balance") { ApplicationArea = All; }
                field(Balance; Rec.Balance) { ApplicationArea = All; Visible = false; }
                field("Amount Payable"; Rec."Amount Payable") { ApplicationArea = All; Style = Strong; ToolTip = 'Specifies the amount of the guide.'; }
                field("Credit Carried Forward"; Rec."Credit Carried Forward") { ApplicationArea = All; ToolTip = 'Specifies the credit carried to the next settlement.'; }
                field("Guide Type"; Rec."Guide Type") { ApplicationArea = All; ToolTip = 'Specifies the guide used to pay the tax.'; }
                field("Revenue Code"; Rec."Revenue Code") { ApplicationArea = All; }
                field("Vendor No."; Rec."Vendor No.") { ApplicationArea = All; }
                field("Due Date"; Rec."Due Date") { ApplicationArea = All; ToolTip = 'Specifies the due date of the guide. It comes from the tax due date setup and can be changed.'; }
                field("Adjustment Account"; Rec."Adjustment Account") { ApplicationArea = All; Visible = false; }
                field("No. of Entries"; Rec."No. of Entries") { ApplicationArea = All; ToolTip = 'Specifies how many documents make up the line.'; }
                field("Vendor Ledger Entry No."; Rec."Vendor Ledger Entry No.") { ApplicationArea = All; ToolTip = 'Specifies the payable created when the settlement was posted.'; }
            }
        }
    }

    trigger OnModifyRecord(): Boolean
    begin
        Rec.UpdateBalance();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec.UpdateBalance();
    end;
}
