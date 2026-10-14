page 50124 "NFB Tax Settlement"
{
    PageType = Document;
    SourceTable = "NFB Tax Settlement Header";
    Caption = 'NF-e Tax Settlement';
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                Editable = IsOpen;
                field("No."; Rec."No.") { ApplicationArea = All; ToolTip = 'Specifies the number of the settlement.'; }
                field("Starting Date"; Rec."Starting Date") { ApplicationArea = All; }
                field("Ending Date"; Rec."Ending Date") { ApplicationArea = All; ToolTip = 'Specifies the last day of the settled month.'; }
                field(Description; Rec.Description) { ApplicationArea = All; ToolTip = 'Specifies the description of the settlement.'; }
                field("Posting Date"; Rec."Posting Date") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; ToolTip = 'Specifies whether the settlement is open or posted.'; }
                field("Calculated At"; Rec."Calculated At") { ApplicationArea = All; ToolTip = 'Specifies when the settlement was last calculated. Calculate again after posting more documents of the month.'; }
                field("Total Payable"; Rec."Total Payable") { ApplicationArea = All; ToolTip = 'Specifies the total of the guides of the settlement.'; }
                field("Total Credit Carried Forward"; Rec."Total Credit Carried Forward") { ApplicationArea = All; ToolTip = 'Specifies the total credit carried to the next settlement.'; }
                field("Posted At"; Rec."Posted At") { ApplicationArea = All; ToolTip = 'Specifies when the settlement was posted.'; }
                field("Posted By"; Rec."Posted By") { ApplicationArea = All; ToolTip = 'Specifies who posted the settlement.'; }
            }
            part(Lines; "NFB Tax Settlement Subform")
            {
                ApplicationArea = All;
                Caption = 'Taxes';
                Editable = IsOpen;
                SubPageLink = "Settlement No." = field("No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CalculateSettlement)
            {
                ApplicationArea = All;
                Caption = 'Calculate';
                Image = Calculate;
                ToolTip = 'Reads the taxes of the invoices and credit memos posted in the month and the credit carried from the previous settlement. Other debits and other credits typed on the lines are kept.';

                trigger OnAction()
                var
                    NFBTaxSettlement: Codeunit "NFB Tax Settlement";
                begin
                    CurrPage.SaveRecord();
                    NFBTaxSettlement.Calculate(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(PostSettlement)
            {
                ApplicationArea = All;
                Caption = 'Post';
                Image = Post;
                ToolTip = 'Clears the tax accounts of the month and creates one payable per guide for the tax authority vendor.';

                trigger OnAction()
                var
                    NFBTaxSettlement: Codeunit "NFB Tax Settlement";
                begin
                    CurrPage.SaveRecord();
                    NFBTaxSettlement.Post(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(ReopenSettlement)
            {
                ApplicationArea = All;
                Caption = 'Reopen';
                Image = ReOpen;
                ToolTip = 'Reopens a posted settlement whose G/L register was reversed with Reverse Register.';

                trigger OnAction()
                var
                    NFBTaxSettlement: Codeunit "NFB Tax Settlement";
                begin
                    NFBTaxSettlement.Reopen(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action(Entries)
            {
                ApplicationArea = All;
                Caption = 'Documents';
                Image = LedgerEntries;
                ToolTip = 'Shows the posted documents and the tax amounts used in the settlement.';

                trigger OnAction()
                var
                    NFBTaxSettlementEntry: Record "NFB Tax Settlement Entry";
                begin
                    NFBTaxSettlementEntry.SetRange("Settlement No.", Rec."No.");
                    Page.Run(Page::"NFB Tax Settlement Entries", NFBTaxSettlementEntry);
                end;
            }
            action(Payables)
            {
                ApplicationArea = All;
                Caption = 'Payables';
                Image = VendorLedger;
                ToolTip = 'Shows the vendor ledger entries created for the guides.';

                trigger OnAction()
                var
                    NFBTaxSettlement: Codeunit "NFB Tax Settlement";
                begin
                    NFBTaxSettlement.ShowPayables(Rec);
                end;
            }
            action(DueDateSetup)
            {
                ApplicationArea = All;
                Caption = 'Tax Due Date Setup';
                Image = DueDate;
                ToolTip = 'Opens the guide, vendor and due date of each tax.';
                RunObject = page "NFB Tax Due Date Setup";
            }
        }
        area(Reporting)
        {
            action(PrintSettlement)
            {
                ApplicationArea = All;
                Caption = 'Print';
                Image = Print;
                ToolTip = 'Prints the settlement, one line per tax.';

                trigger OnAction()
                var
                    NFBTaxSettlementHeader: Record "NFB Tax Settlement Header";
                begin
                    NFBTaxSettlementHeader.SetRange("No.", Rec."No.");
                    Report.Run(Report::"NFB Tax Settlement", true, false, NFBTaxSettlementHeader);
                end;
            }
        }
        area(Promoted)
        {
            actionref(CalculateSettlement_Promoted; CalculateSettlement) { }
            actionref(PostSettlement_Promoted; PostSettlement) { }
            actionref(Entries_Promoted; Entries) { }
            actionref(Payables_Promoted; Payables) { }
            actionref(PrintSettlement_Promoted; PrintSettlement) { }
        }
    }

    var
        IsOpen: Boolean;

    trigger OnAfterGetRecord()
    begin
        IsOpen := Rec.Status = Rec.Status::Open;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        IsOpen := true;
    end;
}
