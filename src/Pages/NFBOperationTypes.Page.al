page 50107 "NFB Operation Types"
{
    PageType = List;
    SourceTable = "NFB Operation Type";
    Caption = 'NF-e Operation Types';
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
                field("Nature of Operation"; Rec."Nature of Operation") { ApplicationArea = All; }
                field(Direction; Rec.Direction) { ApplicationArea = All; }
                field(Purpose; Rec.Purpose) { ApplicationArea = All; }
                field("Presence Indicator"; Rec."Presence Indicator") { ApplicationArea = All; }
                field("CFOP Internal"; Rec."CFOP Internal") { ApplicationArea = All; }
                field("CFOP Interstate"; Rec."CFOP Interstate") { ApplicationArea = All; }
                field("CFOP Exterior"; Rec."CFOP Exterior") { ApplicationArea = All; }
                field("Issue NF-e"; Rec."Issue NF-e") { ApplicationArea = All; }
                field("Calculate Taxes"; Rec."Calculate Taxes") { ApplicationArea = All; }
                field("Post Taxes"; Rec."Post Taxes") { ApplicationArea = All; }
                field("Requires Reference"; Rec."Requires Reference") { ApplicationArea = All; }
                field(Series; Rec.Series) { ApplicationArea = All; }
            }
        }
    }
}
