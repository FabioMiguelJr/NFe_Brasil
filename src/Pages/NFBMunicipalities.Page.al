page 50102 "NFB Municipalities"
{
    PageType = List;
    SourceTable = "NFB Municipality";
    Caption = 'IBGE Municipalities';
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Code; Rec.Code) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(UF; Rec.UF) { ApplicationArea = All; }
                field("UF Code"; Rec."UF Code") { ApplicationArea = All; }
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
                    NFBDataImport.ImportMunicipalities();
                end;
            }
        }
    }
}
