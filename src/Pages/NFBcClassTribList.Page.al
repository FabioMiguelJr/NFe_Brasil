page 50105 "NFB cClassTrib List"
{
    PageType = List;
    SourceTable = "NFB cClassTrib";
    Caption = 'IBS/CBS Classification (cClassTrib)';
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Code; Rec.Code) { ApplicationArea = All; }
                field(CST; Rec.CST) { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field("IBS Reduction %"; Rec."IBS Reduction %") { ApplicationArea = All; }
                field("CBS Reduction %"; Rec."CBS Reduction %") { ApplicationArea = All; }
                field("Starting Date"; Rec."Starting Date") { ApplicationArea = All; }
                field("Ending Date"; Rec."Ending Date") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ImportCsv)
            {
                ApplicationArea = All;
                Caption = 'Import CSV';
                Image = Import;
                ToolTip = 'Import records from a semicolon-separated file with a header row.';

                trigger OnAction()
                var
                    NFBDataImport: Codeunit "NFB Data Import";
                begin
                    NFBDataImport.ImportcClassTrib();
                end;
            }
        }
    }
}
