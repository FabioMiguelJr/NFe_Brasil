page 50127 "NFB Tax Settlement Entries"
{
    PageType = List;
    SourceTable = "NFB Tax Settlement Entry";
    Caption = 'NF-e Tax Settlement Documents';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Entries)
            {
                field("Tax Type"; Rec."Tax Type") { ApplicationArea = All; ToolTip = 'Specifies the tax.'; }
                field("State Code"; Rec."State Code") { ApplicationArea = All; ToolTip = 'Specifies the state the tax is owed to, when it is not the issuer''s state.'; }
                field("Posting Date"; Rec."Posting Date") { ApplicationArea = All; ToolTip = 'Specifies the posting date of the document.'; }
                field("Source Doc. Type"; Rec."Source Doc. Type") { ApplicationArea = All; ToolTip = 'Specifies the type of the posted document.'; }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posted document.';

                    trigger OnDrillDown()
                    begin
                        Rec.ShowDocument();
                    end;
                }
                field("Source No."; Rec."Source No.") { ApplicationArea = All; ToolTip = 'Specifies the customer or vendor of the document.'; }
                field("Base Amount"; Rec."Base Amount") { ApplicationArea = All; ToolTip = 'Specifies the tax base of the document.'; }
                field("Output Tax"; Rec."Output Tax") { ApplicationArea = All; ToolTip = 'Specifies the tax debited by the sale. Credit memos are negative.'; }
                field("Input Tax"; Rec."Input Tax") { ApplicationArea = All; ToolTip = 'Specifies the tax credited by the purchase. Credit memos are negative.'; }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(ShowDocument)
            {
                ApplicationArea = All;
                Caption = 'Show Document';
                Image = Document;
                ToolTip = 'Opens the posted document.';

                trigger OnAction()
                begin
                    Rec.ShowDocument();
                end;
            }
        }
    }
}
