page 50110 "NFB Document Card"
{
    PageType = Document;
    SourceTable = "NFB Document Header";
    Caption = 'NF-e';
    ApplicationArea = All;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            group(Identification)
            {
                Caption = 'Identification';
                field("No."; Rec."No.") { ApplicationArea = All; Editable = false; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Issue Mode"; Rec."Issue Mode") { ApplicationArea = All; }
                field(Environment; Rec.Environment) { ApplicationArea = All; }
                field("Source Doc. Type"; Rec."Source Doc. Type") { ApplicationArea = All; }
                field("Source Doc. No."; Rec."Source Doc. No.") { ApplicationArea = All; }
                field("Operation Type"; Rec."Operation Type") { ApplicationArea = All; }
                field("Nature of Operation"; Rec."Nature of Operation") { ApplicationArea = All; }
                field(Model; Rec.Model) { ApplicationArea = All; Editable = false; }
                field(Series; Rec.Series) { ApplicationArea = All; }
                field("NF No."; Rec."NF No.") { ApplicationArea = All; }
                field("Access Key"; Rec."Access Key") { ApplicationArea = All; }
                field("Issue DateTime"; Rec."Issue DateTime") { ApplicationArea = All; }
                field("Exit DateTime"; Rec."Exit DateTime") { ApplicationArea = All; }
                field(Direction; Rec.Direction) { ApplicationArea = All; }
                field("Destination Id"; Rec."Destination Id") { ApplicationArea = All; }
                field(Purpose; Rec.Purpose) { ApplicationArea = All; }
                field("Final Consumer"; Rec."Final Consumer") { ApplicationArea = All; }
                field("Presence Indicator"; Rec."Presence Indicator") { ApplicationArea = All; }
                field("Validation Errors"; Rec."Validation Errors") { ApplicationArea = All; }
            }
            part(Lines; "NFB Document Subform")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
            group(Issuer)
            {
                Caption = 'Issuer';
                field("Issuer Name"; Rec."Issuer Name") { ApplicationArea = All; }
                field("Issuer CNPJ"; Rec."Issuer CNPJ") { ApplicationArea = All; }
                field("Issuer IE"; Rec."Issuer IE") { ApplicationArea = All; }
                field("Issuer CRT"; Rec."Issuer CRT") { ApplicationArea = All; }
                field("Issuer UF"; Rec."Issuer UF") { ApplicationArea = All; }
                field("Issuer UF Code"; Rec."Issuer UF Code") { ApplicationArea = All; }
                field("Taxable Event Municipality"; Rec."Taxable Event Municipality") { ApplicationArea = All; }
                field("Issuer Location Code"; Rec."Issuer Location Code") { ApplicationArea = All; }
            }
            group(Recipient)
            {
                Caption = 'Recipient';
                field("Recipient No."; Rec."Recipient No.") { ApplicationArea = All; }
                field("Recipient Name"; Rec."Recipient Name") { ApplicationArea = All; }
                field("Recipient Type"; Rec."Recipient Type") { ApplicationArea = All; }
                field("Recipient CPF/CNPJ"; Rec."Recipient CPF/CNPJ") { ApplicationArea = All; }
                field("Recipient Foreign Id"; Rec."Recipient Foreign Id") { ApplicationArea = All; }
                field("Recipient IE Indicator"; Rec."Recipient IE Indicator") { ApplicationArea = All; }
                field("Recipient IE"; Rec."Recipient IE") { ApplicationArea = All; }
                field("Recipient SUFRAMA"; Rec."Recipient SUFRAMA") { ApplicationArea = All; }
                field("Recipient Address"; Rec."Recipient Address") { ApplicationArea = All; }
                field("Recipient Address No."; Rec."Recipient Address No.") { ApplicationArea = All; }
                field("Recipient Address 2"; Rec."Recipient Address 2") { ApplicationArea = All; }
                field("Recipient District"; Rec."Recipient District") { ApplicationArea = All; }
                field("Recipient Municipality Code"; Rec."Recipient Municipality Code") { ApplicationArea = All; }
                field("Recipient City"; Rec."Recipient City") { ApplicationArea = All; }
                field("Recipient UF"; Rec."Recipient UF") { ApplicationArea = All; }
                field("Recipient Post Code"; Rec."Recipient Post Code") { ApplicationArea = All; }
                field("Recipient BACEN Code"; Rec."Recipient BACEN Code") { ApplicationArea = All; }
                field("Recipient Country"; Rec."Recipient Country") { ApplicationArea = All; }
                field("Recipient Phone"; Rec."Recipient Phone") { ApplicationArea = All; }
                field("Recipient E-Mail"; Rec."Recipient E-Mail") { ApplicationArea = All; }
            }
            group(Totals)
            {
                Caption = 'Totals';
                field("Products Amount"; Rec."Products Amount") { ApplicationArea = All; }
                field("Discount Amount"; Rec."Discount Amount") { ApplicationArea = All; }
                field("Freight Amount"; Rec."Freight Amount") { ApplicationArea = All; }
                field("Insurance Amount"; Rec."Insurance Amount") { ApplicationArea = All; }
                field("Other Expenses"; Rec."Other Expenses") { ApplicationArea = All; }
                field("ICMS Base"; Rec."ICMS Base") { ApplicationArea = All; }
                field("ICMS Amount"; Rec."ICMS Amount") { ApplicationArea = All; }
                field("FCP Amount"; Rec."FCP Amount") { ApplicationArea = All; }
                field("ICMS ST Base"; Rec."ICMS ST Base") { ApplicationArea = All; }
                field("ICMS ST Amount"; Rec."ICMS ST Amount") { ApplicationArea = All; }
                field("FCP ST Amount"; Rec."FCP ST Amount") { ApplicationArea = All; }
                field("DIFAL Dest. Amount"; Rec."DIFAL Dest. Amount") { ApplicationArea = All; }
                field("FCP Dest. Amount"; Rec."FCP Dest. Amount") { ApplicationArea = All; }
                field("IPI Amount"; Rec."IPI Amount") { ApplicationArea = All; }
                field("II Amount"; Rec."II Amount") { ApplicationArea = All; }
                field("PIS Amount"; Rec."PIS Amount") { ApplicationArea = All; }
                field("COFINS Amount"; Rec."COFINS Amount") { ApplicationArea = All; }
                field("IBS/CBS Base"; Rec."IBS/CBS Base") { ApplicationArea = All; }
                field("IBS UF Amount"; Rec."IBS UF Amount") { ApplicationArea = All; }
                field("IBS Mun. Amount"; Rec."IBS Mun. Amount") { ApplicationArea = All; }
                field("CBS Amount"; Rec."CBS Amount") { ApplicationArea = All; }
                field("Invoice Amount"; Rec."Invoice Amount") { ApplicationArea = All; Style = Strong; }
            }
            part(Payments; "NFB Payments Subform")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
            part(Installments; "NFB Installments Subform")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
            part(Transport; "NFB Transport Part")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
            part(References; "NFB References Subform")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
            group(AdditionalInfo)
            {
                Caption = 'Additional Information';
                field("Additional Info"; Rec."Additional Info") { ApplicationArea = All; MultiLine = true; }
                field("Fiscal Info"; Rec."Fiscal Info") { ApplicationArea = All; MultiLine = true; }
                field("Export Shipping UF"; Rec."Export Shipping UF") { ApplicationArea = All; }
                field("Export Shipping Place"; Rec."Export Shipping Place") { ApplicationArea = All; }
            }
            group(Authorization)
            {
                Caption = 'SEFAZ Return';
                field("Status Code"; Rec."Status Code") { ApplicationArea = All; }
                field("Status Reason"; Rec."Status Reason") { ApplicationArea = All; }
                field("Protocol No."; Rec."Protocol No.") { ApplicationArea = All; }
                field("Authorization DateTime"; Rec."Authorization DateTime") { ApplicationArea = All; }
                field("Provider Id"; Rec."Provider Id") { ApplicationArea = All; ToolTip = 'Specifies the id of the NF-e at PlugNotas.'; }
                field("Provider Status"; Rec."Provider Status") { ApplicationArea = All; ToolTip = 'Specifies the last status returned by PlugNotas.'; }
                field("Last Status Query"; Rec."Last Status Query") { ApplicationArea = All; ToolTip = 'Specifies when the status was last queried.'; }
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
                    CurrPage.Update(false);
                end;
            }
            action(SendNFe)
            {
                ApplicationArea = All;
                Caption = 'Send';
                Image = SendTo;
                ToolTip = 'Validates the NF-e, generates the XML and sends it through the issue mode of NF-e Setup (PlugNotas or File Only).';

                trigger OnAction()
                var
                    NFBProviderMgt: Codeunit "NFB Provider Mgt";
                begin
                    NFBProviderMgt.Send(Rec, true);
                    CurrPage.Update(false);
                end;
            }
            action(QueryStatus)
            {
                ApplicationArea = All;
                Caption = 'Query Status';
                Image = Refresh;
                ToolTip = 'Asks the authorizer for the result of the sent NF-e and downloads the authorized XML and DANFE.';

                trigger OnAction()
                var
                    NFBProviderMgt: Codeunit "NFB Provider Mgt";
                begin
                    NFBProviderMgt.QueryStatus(Rec, true);
                    CurrPage.Update(false);
                end;
            }
            action(CancelNFe)
            {
                ApplicationArea = All;
                Caption = 'Cancel NF-e';
                Image = Cancel;
                ToolTip = 'Requests the cancellation of the authorized NF-e. SEFAZ accepts it up to 24 hours after the authorization.';

                trigger OnAction()
                var
                    NFBProviderMgt: Codeunit "NFB Provider Mgt";
                begin
                    NFBProviderMgt.RequestCancellation(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(CorrectionLetter)
            {
                ApplicationArea = All;
                Caption = 'Correction Letter (CC-e)';
                Image = EditLines;
                ToolTip = 'Requests a correction letter for the authorized NF-e.';

                trigger OnAction()
                var
                    NFBProviderMgt: Codeunit "NFB Provider Mgt";
                begin
                    NFBProviderMgt.RequestCorrectionLetter(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(DownloadPdf)
            {
                ApplicationArea = All;
                Caption = 'Download DANFE (PDF)';
                Image = SendAsPDF;
                ToolTip = 'Downloads the DANFE returned by the provider. If there is none, prints the DANFE of the extension.';

                trigger OnAction()
                var
                    NFBProviderMgt: Codeunit "NFB Provider Mgt";
                begin
                    NFBProviderMgt.DownloadPdf(Rec);
                end;
            }
            action(ImportAuthorizedXml)
            {
                ApplicationArea = All;
                Caption = 'Import Authorized XML';
                Image = ImportCodes;
                ToolTip = 'Imports the authorized XML (nfeProc) or an event XML (procEventoNFe) produced by another system. The NF-e is found by the access key.';

                trigger OnAction()
                var
                    NFBProviderMgt: Codeunit "NFB Provider Mgt";
                begin
                    NFBProviderMgt.ImportAuthorizedXml();
                    CurrPage.Update(false);
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
            action(RecalculateTotals)
            {
                ApplicationArea = All;
                Caption = 'Recalculate Totals';
                Image = Calculate;

                trigger OnAction()
                var
                    NFBDocumentBuilder: Codeunit "NFB Document Builder";
                begin
                    Rec.TestStatusOpen();
                    NFBDocumentBuilder.UpdateTotals(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action(Events)
            {
                ApplicationArea = All;
                Caption = 'Events';
                Image = History;
                ToolTip = 'Shows the cancellation and correction letter events of this NF-e.';
                RunObject = page "NFB Document Events";
                RunPageLink = "Document No." = field("No.");
            }
            action(Files)
            {
                ApplicationArea = All;
                Caption = 'Files';
                Image = Documents;
                ToolTip = 'Shows the XML and other files saved for this NF-e.';
                RunObject = page "NFB Document Files";
                RunPageLink = "Document No." = field("No.");
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
            actionref(SendNFe_Promoted; SendNFe) { }
            actionref(QueryStatus_Promoted; QueryStatus) { }
            actionref(CancelNFe_Promoted; CancelNFe) { }
            actionref(CorrectionLetter_Promoted; CorrectionLetter) { }
            actionref(SourceDocument_Promoted; SourceDocument) { }
            actionref(GenerateXml_Promoted; GenerateXml) { }
            actionref(DownloadXml_Promoted; DownloadXml) { }
            actionref(PrintDANFE_Promoted; PrintDANFE) { }
        }
    }

    trigger OnModifyRecord(): Boolean
    begin
        Rec.TestStatusOpen();
        exit(true);
    end;
}
