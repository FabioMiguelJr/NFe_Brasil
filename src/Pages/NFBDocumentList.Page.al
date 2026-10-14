page 50209 "NFB Document List"
{
    PageType = List;
    SourceTable = "NFB Document Header";
    Caption = 'NF-e Monitor';
    ApplicationArea = All;
    UsageCategory = Lists;
    CardPageId = "NFB Document Card";
    Editable = false;
    SourceTableView = sorting("No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; StyleExpr = StatusStyle; }
                field(Series; Rec.Series) { ApplicationArea = All; }
                field("NF No."; Rec."NF No.") { ApplicationArea = All; }
                field("Issue DateTime"; Rec."Issue DateTime") { ApplicationArea = All; }
                field("Source Doc. Type"; Rec."Source Doc. Type") { ApplicationArea = All; }
                field("Source Doc. No."; Rec."Source Doc. No.") { ApplicationArea = All; }
                field("Operation Type"; Rec."Operation Type") { ApplicationArea = All; }
                field("Recipient Name"; Rec."Recipient Name") { ApplicationArea = All; }
                field("Recipient CPF/CNPJ"; Rec."Recipient CPF/CNPJ") { ApplicationArea = All; }
                field("Invoice Amount"; Rec."Invoice Amount") { ApplicationArea = All; }
                field("Access Key"; Rec."Access Key") { ApplicationArea = All; }
                field("Status Code"; Rec."Status Code") { ApplicationArea = All; }
                field("Status Reason"; Rec."Status Reason") { ApplicationArea = All; }
                field("Validation Errors"; Rec."Validation Errors") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ValidateNFe)
            {
                ApplicationArea = All;
                Caption = 'Validate';
                Image = CheckRulesSyntax;
                ToolTip = 'Checks the NF-e and, when valid, assigns its number and access key.';

                trigger OnAction()
                var
                    NFBDocumentMgt: Codeunit "NFB Document Mgt";
                begin
                    NFBDocumentMgt.ValidateDocument(Rec, true);
                end;
            }
            action(SourceDocument)
            {
                ApplicationArea = All;
                Caption = 'Source Document';
                Image = Document;

                trigger OnAction()
                var
                    NFBDocumentMgt: Codeunit "NFB Document Mgt";
                begin
                    NFBDocumentMgt.OpenSourceDocument(Rec);
                end;
            }
        }
        area(Promoted)
        {
            actionref(ValidateNFe_Promoted; ValidateNFe) { }
            actionref(SourceDocument_Promoted; SourceDocument) { }
        }
    }

    trigger OnAfterGetRecord()
    begin
        StatusStyle := GetStatusStyle(Rec.Status);
    end;

    procedure GetStatusStyle(Status: Enum "NFB Document Status"): Text
    begin
        case Status of
            Status::Authorized:
                exit('Favorable');
            Status::Rejected, Status::Denied:
                exit('Unfavorable');
            Status::Cancelled, Status::Voided:
                exit('Subordinate');
            else
                exit('Standard');
        end;
    end;

    var
        StatusStyle: Text;
}
