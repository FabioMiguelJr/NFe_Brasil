page 50203 "NFB NCM List"
{
    PageType = List;
    SourceTable = "NFB NCM";
    Caption = 'NCM';
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
                field(CEST; Rec.CEST) { ApplicationArea = All; }
                field("IPI %"; Rec."IPI %") { ApplicationArea = All; }
                field("Ex TIPI"; Rec."Ex TIPI") { ApplicationArea = All; }
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
                    NFBDataImport.ImportNCM();
                end;
            }
        }
    }
}
