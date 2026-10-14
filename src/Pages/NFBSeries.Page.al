page 50201 "NFB Series"
{
    PageType = List;
    SourceTable = "NFB Series";
    Caption = 'NF-e Series';
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Model; Rec.Model) { ApplicationArea = All; }
                field(Series; Rec.Series) { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field("No. Series"; Rec."No. Series") { ApplicationArea = All; }
                field(Blocked; Rec.Blocked) { ApplicationArea = All; }
            }
        }
    }
}
