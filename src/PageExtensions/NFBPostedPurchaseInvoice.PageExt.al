pageextension 50228 "NFB Posted Purchase Invoice" extends "Posted Purchase Invoice"
{
    layout
    {
        addlast(General)
        {
            group(NFBFiscal)
            {
                Caption = 'NF-e';
                field("NFB Operation Type"; Rec."NFB Operation Type") { ApplicationArea = All; }
                field("NFB Nature of Operation"; Rec."NFB Nature of Operation") { ApplicationArea = All; }
                field("NFB Purpose"; Rec."NFB Purpose") { ApplicationArea = All; }
                field("NFB Status"; Rec."NFB Status") { ApplicationArea = All; }
                field("NFB Document No."; Rec."NFB Document No.") { ApplicationArea = All; }
                field("NFB Access Key"; Rec."NFB Access Key") { ApplicationArea = All; }
            }
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
                        NFBDocumentMgt.CreateAndOpen("NFB Source Doc. Type"::"Purchase Invoice", Rec."No.");
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
                        NFBDocumentMgt.OpenForSource("NFB Source Doc. Type"::"Purchase Invoice", Rec."No.");
                    end;
                }
            }
        }
    }
}
