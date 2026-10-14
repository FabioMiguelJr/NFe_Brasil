page 50114 "NFB Import Declarations"
{
    PageType = List;
    SourceTable = "NFB Import Declaration";
    Caption = 'Import Declarations (DI)';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field("Declaration No."; Rec."Declaration No.") { ApplicationArea = All; }
                field("Declaration Date"; Rec."Declaration Date") { ApplicationArea = All; }
                field("Customs Place"; Rec."Customs Place") { ApplicationArea = All; }
                field("Customs UF"; Rec."Customs UF") { ApplicationArea = All; }
                field("Customs Date"; Rec."Customs Date") { ApplicationArea = All; }
                field("Transport Mode"; Rec."Transport Mode") { ApplicationArea = All; }
                field("AFRMM Amount"; Rec."AFRMM Amount") { ApplicationArea = All; }
                field("Intermediation Type"; Rec."Intermediation Type") { ApplicationArea = All; }
                field("Exporter Code"; Rec."Exporter Code") { ApplicationArea = All; }
                field("Addition No."; Rec."Addition No.") { ApplicationArea = All; }
                field("Addition Seq."; Rec."Addition Seq.") { ApplicationArea = All; }
                field("Manufacturer Code"; Rec."Manufacturer Code") { ApplicationArea = All; }
                field("II Base"; Rec."II Base") { ApplicationArea = All; }
                field("II Amount"; Rec."II Amount") { ApplicationArea = All; }
                field("Customs Expenses"; Rec."Customs Expenses") { ApplicationArea = All; }
                field("IOF Amount"; Rec."IOF Amount") { ApplicationArea = All; }
            }
        }
    }
}
