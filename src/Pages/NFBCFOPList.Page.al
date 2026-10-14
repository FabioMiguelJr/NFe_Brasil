page 50104 "NFB CFOP List"
{
    PageType = List;
    SourceTable = "NFB CFOP";
    Caption = 'CFOP';
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Code; Rec.Code) { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field(Direction; Rec.Direction) { ApplicationArea = All; }
                field(Destination; Rec.Destination) { ApplicationArea = All; }
                field("Is Return"; Rec."Is Return") { ApplicationArea = All; }
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
                    NFBDataImport.ImportCFOP();
                end;
            }
        }
    }
}
