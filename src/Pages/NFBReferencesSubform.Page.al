page 50115 "NFB References Subform"
{
    PageType = ListPart;
    SourceTable = "NFB Document Reference";
    Caption = 'Referenced NF-e (NFref)';
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Referenced Access Key"; Rec."Referenced Access Key") { ApplicationArea = All; }
                field("Referenced Document No."; Rec."Referenced Document No.") { ApplicationArea = All; }
            }
        }
    }
}
