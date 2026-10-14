page 50122 "NFB Document Events"
{
    PageType = List;
    SourceTable = "NFB Document Event";
    Caption = 'NF-e Events';
    ApplicationArea = All;
    UsageCategory = History;
    Editable = false;
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Events)
            {
                field("Document No."; Rec."Document No.") { ApplicationArea = All; ToolTip = 'Specifies the fiscal document of the event.'; }
                field("Event Type"; Rec."Event Type") { ApplicationArea = All; ToolTip = 'Specifies whether the event is a cancellation or a correction letter.'; }
                field("Sequence No."; Rec."Sequence No.") { ApplicationArea = All; ToolTip = 'Specifies the sequence of the event for the NF-e. Each new correction letter replaces the previous one.'; }
                field(Status; Rec.Status) { ApplicationArea = All; ToolTip = 'Specifies whether the event is waiting for the authorizer, registered or rejected.'; }
                field("Event Text"; Rec."Event Text") { ApplicationArea = All; ToolTip = 'Specifies the justification of the cancellation or the text of the correction.'; }
                field("Status Code"; Rec."Status Code") { ApplicationArea = All; ToolTip = 'Specifies the status code returned by the authorizer.'; }
                field("Status Reason"; Rec."Status Reason") { ApplicationArea = All; ToolTip = 'Specifies the message returned by the authorizer.'; }
                field("Protocol No."; Rec."Protocol No.") { ApplicationArea = All; ToolTip = 'Specifies the protocol of the registered event.'; }
                field("Registered At"; Rec."Registered At") { ApplicationArea = All; ToolTip = 'Specifies when the authorizer registered the event.'; }
                field("Created At"; Rec."Created At") { ApplicationArea = All; ToolTip = 'Specifies when the event was requested.'; }
                field("Created By"; Rec."Created By") { ApplicationArea = All; ToolTip = 'Specifies who requested the event.'; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(QueryStatus)
            {
                ApplicationArea = All;
                Caption = 'Query Status';
                Image = Refresh;
                ToolTip = 'Asks the authorizer for the result of the pending event.';

                trigger OnAction()
                var
                    NFBProviderMgt: Codeunit "NFB Provider Mgt";
                begin
                    NFBProviderMgt.QueryEventStatus(Rec, true);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            actionref(QueryStatus_Promoted; QueryStatus) { }
        }
    }
}
