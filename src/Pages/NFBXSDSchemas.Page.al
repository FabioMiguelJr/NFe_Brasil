page 50121 "NFB XSD Schemas"
{
    PageType = List;
    SourceTable = "NFB XSD Schema";
    Caption = 'NF-e XSD Schemas';
    ApplicationArea = All;
    UsageCategory = Administration;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Schemas)
            {
                field("File Name"; Rec."File Name") { ApplicationArea = All; Editable = false; ToolTip = 'Specifies the schema file name. Include statements refer to the other files by this name.'; }
                field("Main Schema"; Rec."Main Schema") { ApplicationArea = All; }
                field("Size (Bytes)"; Rec."Size (Bytes)") { ApplicationArea = All; Editable = false; ToolTip = 'Specifies the file size.'; }
                field("Imported At"; Rec."Imported At") { ApplicationArea = All; Editable = false; ToolTip = 'Specifies when the file was imported.'; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ImportSchemas)
            {
                ApplicationArea = All;
                Caption = 'Import Schemas';
                Image = Import;
                ToolTip = 'Imports the schema package published on the NF-e portal (.zip) or a single .xsd file. Existing files with the same name are replaced.';

                trigger OnAction()
                var
                    NFBFileMgt: Codeunit "NFB File Mgt";
                begin
                    NFBFileMgt.ImportSchemas();
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            actionref(ImportSchemas_Promoted; ImportSchemas) { }
        }
    }
}
