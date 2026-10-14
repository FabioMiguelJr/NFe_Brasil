page 50106 "NFB Tax Rules"
{
    PageType = List;
    SourceTable = "NFB Tax Rule";
    Caption = 'NF-e Tax Rules';
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
                field("Operation Type"; Rec."Operation Type") { ApplicationArea = All; }
                field("Tax Group"; Rec."Tax Group") { ApplicationArea = All; }
                field(Destination; Rec.Destination) { ApplicationArea = All; }
                field("Destination UF"; Rec."Destination UF") { ApplicationArea = All; }
                field("IE Indicator"; Rec."IE Indicator") { ApplicationArea = All; }
                field("Final Consumer"; Rec."Final Consumer") { ApplicationArea = All; }
                field(CFOP; Rec.CFOP) { ApplicationArea = All; }
                field("ICMS CST"; Rec."ICMS CST") { ApplicationArea = All; }
                field("ICMS %"; Rec."ICMS %") { ApplicationArea = All; }
                field("ICMS Base Reduction %"; Rec."ICMS Base Reduction %") { ApplicationArea = All; }
                field("FCP %"; Rec."FCP %") { ApplicationArea = All; }
                field("ICMS ST MVA %"; Rec."ICMS ST MVA %") { ApplicationArea = All; }
                field("ICMS ST Internal %"; Rec."ICMS ST Internal %") { ApplicationArea = All; }
                field("ICMS ST Base Reduction %"; Rec."ICMS ST Base Reduction %") { ApplicationArea = All; }
                field("FCP ST %"; Rec."FCP ST %") { ApplicationArea = All; }
                field("DIFAL Internal Dest. %"; Rec."DIFAL Internal Dest. %") { ApplicationArea = All; }
                field("FCP Dest. %"; Rec."FCP Dest. %") { ApplicationArea = All; }
                field("IPI CST"; Rec."IPI CST") { ApplicationArea = All; }
                field("Use NCM IPI %"; Rec."Use NCM IPI %") { ApplicationArea = All; }
                field("IPI %"; Rec."IPI %") { ApplicationArea = All; }
                field("IPI Enq. Code"; Rec."IPI Enq. Code") { ApplicationArea = All; }
                field("PIS CST"; Rec."PIS CST") { ApplicationArea = All; }
                field("PIS %"; Rec."PIS %") { ApplicationArea = All; }
                field("COFINS CST"; Rec."COFINS CST") { ApplicationArea = All; }
                field("COFINS %"; Rec."COFINS %") { ApplicationArea = All; }
                field("IBS/CBS CST"; Rec."IBS/CBS CST") { ApplicationArea = All; }
                field(cClassTrib; Rec.cClassTrib) { ApplicationArea = All; }
                field("IBS UF %"; Rec."IBS UF %") { ApplicationArea = All; }
                field("IBS Mun. %"; Rec."IBS Mun. %") { ApplicationArea = All; }
                field("CBS %"; Rec."CBS %") { ApplicationArea = All; }
                field("Additional Info"; Rec."Additional Info") { ApplicationArea = All; }
            }
        }
    }
}
