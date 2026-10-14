page 50109 "NFB Document List"
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
            action(GenerateXml)
            {
                ApplicationArea = All;
                Caption = 'Generate XML';
                Image = CreateXMLFile;
                ToolTip = 'Validates the NF-e, builds the XML in layout 4.00 and saves it in the NF-e files. The XML is not signed.';

                trigger OnAction()
                var
                    NFBFileMgt: Codeunit "NFB File Mgt";
                begin
                    NFBFileMgt.GenerateXml(Rec, true);
                    CurrPage.Update(false);
                end;
            }
            action(DownloadXml)
            {
                ApplicationArea = All;
                Caption = 'Download XML';
                Image = ExportFile;
                ToolTip = 'Downloads the most recent XML of the NF-e (authorized, signed or unsigned, in this order).';

                trigger OnAction()
                var
                    NFBFileMgt: Codeunit "NFB File Mgt";
                begin
                    NFBFileMgt.DownloadXml(Rec);
                end;
            }
            action(PrintDANFE)
            {
                ApplicationArea = All;
                Caption = 'Print DANFE';
                Image = Print;
                ToolTip = 'Prints the DANFE of the NF-e.';

                trigger OnAction()
                var
                    NFBDocumentHeader: Record "NFB Document Header";
                begin
                    NFBDocumentHeader.SetRange("No.", Rec."No.");
                    Report.Run(Report::"NFB DANFE", true, false, NFBDocumentHeader);
                end;
            }
            action(ExportZip)
            {
                ApplicationArea = All;
                Caption = 'Export XML (ZIP)';
                Image = ExportToExcel;
                ToolTip = 'Exports the XML of the selected NF-e in one ZIP file.';

                trigger OnAction()
                var
                    NFBDocumentHeader: Record "NFB Document Header";
                    NFBFileMgt: Codeunit "NFB File Mgt";
                begin
                    CurrPage.SetSelectionFilter(NFBDocumentHeader);
                    NFBFileMgt.ExportZip(NFBDocumentHeader, 'nfe-xml.zip', true);
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
        area(Navigation)
        {
            action(Files)
            {
                ApplicationArea = All;
                Caption = 'Files';
                Image = Documents;
                ToolTip = 'Shows the XML and other files saved for this NF-e.';
                RunObject = page "NFB Document Files";
                RunPageLink = "Document No." = field("No.");
            }
        }
        area(Reporting)
        {
            action(NFeByPeriod)
            {
                ApplicationArea = All;
                Caption = 'NF-e by Period';
                Image = Report;
                ToolTip = 'Lists the NF-e of a period with their totals and taxes.';
                RunObject = report "NFB NF-e by Period";
            }
            action(ExportBatch)
            {
                ApplicationArea = All;
                Caption = 'Export XML by Period';
                Image = ExportFile;
                ToolTip = 'Exports the XML of all NF-e of a period in one ZIP file.';
                RunObject = report "NFB Export XML Batch";
            }
        }
        area(Promoted)
        {
            actionref(ValidateNFe_Promoted; ValidateNFe) { }
            actionref(SourceDocument_Promoted; SourceDocument) { }
            actionref(GenerateXml_Promoted; GenerateXml) { }
            actionref(DownloadXml_Promoted; DownloadXml) { }
            actionref(PrintDANFE_Promoted; PrintDANFE) { }
            actionref(ExportZip_Promoted; ExportZip) { }
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
