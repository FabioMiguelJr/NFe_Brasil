pageextension 50139 "NFB Posted Sales Credit Memos" extends "Posted Sales Credit Memos"
{
    layout
    {
        addafter("No.")
        {
            field("NFB Status"; Rec."NFB Status") { ApplicationArea = All; }
            field("NFB Access Key"; Rec."NFB Access Key") { ApplicationArea = All; }
        }
    }

    actions
    {
        addlast(Processing)
        {
            group(NFBActions)
            {
                Caption = 'NF-e';
                Image = ElectronicDoc;
                action(NFBCreate)
                {
                    ApplicationArea = All;
                    Caption = 'Create NF-e';
                    Image = CreateDocument;
                    ToolTip = 'Creates the NF-e for this document when it was not created on posting.';

                    trigger OnAction()
                    var
                        NFBDocumentMgt: Codeunit "NFB Document Mgt";
                    begin
                        NFBDocumentMgt.CreateAndOpen("NFB Source Doc. Type"::"Sales Cr. Memo", Rec."No.");
                    end;
                }
                action(NFBOpen)
                {
                    ApplicationArea = All;
                    Caption = 'NF-e';
                    Image = ElectronicDoc;

                    trigger OnAction()
                    var
                        NFBDocumentMgt: Codeunit "NFB Document Mgt";
                    begin
                        NFBDocumentMgt.OpenForSource("NFB Source Doc. Type"::"Sales Cr. Memo", Rec."No.");
                    end;
                }
            }
        }
    }
}
