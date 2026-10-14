page 50120 "NFB Document Files"
{
    PageType = List;
    SourceTable = "NFB Document File";
    Caption = 'NF-e Document Files';
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;
    SourceTableView = sorting("Document No.", "File Type", "Created At") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Files)
            {
                field("Document No."; Rec."Document No.") { ApplicationArea = All; ToolTip = 'Specifies the fiscal document the file belongs to.'; }
                field("File Type"; Rec."File Type") { ApplicationArea = All; ToolTip = 'Specifies the kind of file.'; }
                field("File Name"; Rec."File Name") { ApplicationArea = All; ToolTip = 'Specifies the name used when the file is downloaded.'; }
                field("Access Key"; Rec."Access Key") { ApplicationArea = All; ToolTip = 'Specifies the NF-e access key.'; }
                field("XSD Validated"; Rec."XSD Validated") { ApplicationArea = All; ToolTip = 'Specifies whether the XML passed the SEFAZ schema validation.'; }
                field("Size (Bytes)"; Rec."Size (Bytes)") { ApplicationArea = All; ToolTip = 'Specifies the file size.'; }
                field("Created At"; Rec."Created At") { ApplicationArea = All; ToolTip = 'Specifies when the file was created.'; }
                field("Created By"; Rec."Created By") { ApplicationArea = All; ToolTip = 'Specifies who created the file.'; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Download)
            {
                ApplicationArea = All;
                Caption = 'Download';
                Image = Export;
                ToolTip = 'Downloads the selected file.';

                trigger OnAction()
                var
                    NFBFileMgt: Codeunit "NFB File Mgt";
                begin
                    NFBFileMgt.DownloadFile(Rec);
                end;
            }
        }
        area(Promoted)
        {
            actionref(Download_Promoted; Download) { }
        }
    }
}
