page 50111 "NFB Document Subform"
{
    PageType = ListPart;
    SourceTable = "NFB Document Line";
    Caption = 'Items';
    AutoSplitKey = true;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Item Seq."; Rec."Item Seq.") { ApplicationArea = All; Editable = false; }
                field("Product Code"; Rec."Product Code") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field(GTIN; Rec.GTIN) { ApplicationArea = All; }
                field(NCM; Rec.NCM) { ApplicationArea = All; }
                field(CEST; Rec.CEST) { ApplicationArea = All; }
                field(CFOP; Rec.CFOP) { ApplicationArea = All; }
                field(Origin; Rec.Origin) { ApplicationArea = All; }
                field("Commercial Unit"; Rec."Commercial Unit") { ApplicationArea = All; }
                field("Commercial Quantity"; Rec."Commercial Quantity") { ApplicationArea = All; }
                field("Commercial Unit Price"; Rec."Commercial Unit Price") { ApplicationArea = All; }
                field("Products Amount"; Rec."Products Amount") { ApplicationArea = All; }
                field("Discount Amount"; Rec."Discount Amount") { ApplicationArea = All; }
                field("Taxable Unit"; Rec."Taxable Unit") { ApplicationArea = All; Visible = false; }
                field("Taxable Quantity"; Rec."Taxable Quantity") { ApplicationArea = All; Visible = false; }
                field("Taxable Unit Price"; Rec."Taxable Unit Price") { ApplicationArea = All; Visible = false; }
                field("ICMS CST"; Rec."ICMS CST") { ApplicationArea = All; }
                field("ICMS Base"; Rec."ICMS Base") { ApplicationArea = All; }
                field("ICMS %"; Rec."ICMS %") { ApplicationArea = All; }
                field("ICMS Amount"; Rec."ICMS Amount") { ApplicationArea = All; }
                field("FCP Amount"; Rec."FCP Amount") { ApplicationArea = All; }
                field("ICMS ST Amount"; Rec."ICMS ST Amount") { ApplicationArea = All; }
                field("DIFAL Dest. Amount"; Rec."DIFAL Dest. Amount") { ApplicationArea = All; Visible = false; }
                field("IPI CST"; Rec."IPI CST") { ApplicationArea = All; }
                field("IPI Amount"; Rec."IPI Amount") { ApplicationArea = All; }
                field("PIS CST"; Rec."PIS CST") { ApplicationArea = All; }
                field("PIS Amount"; Rec."PIS Amount") { ApplicationArea = All; }
                field("COFINS CST"; Rec."COFINS CST") { ApplicationArea = All; }
                field("COFINS Amount"; Rec."COFINS Amount") { ApplicationArea = All; }
                field("IBS/CBS CST"; Rec."IBS/CBS CST") { ApplicationArea = All; }
                field(cClassTrib; Rec.cClassTrib) { ApplicationArea = All; }
                field("IBS/CBS Base"; Rec."IBS/CBS Base") { ApplicationArea = All; }
                field("IBS UF Amount"; Rec."IBS UF Amount") { ApplicationArea = All; }
                field("IBS Mun. Amount"; Rec."IBS Mun. Amount") { ApplicationArea = All; }
                field("CBS Amount"; Rec."CBS Amount") { ApplicationArea = All; }
                field("II Amount"; Rec."II Amount") { ApplicationArea = All; Visible = false; }
                field("Additional Info"; Rec."Additional Info") { ApplicationArea = All; Visible = false; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ImportDeclaration)
            {
                ApplicationArea = All;
                Caption = 'Import Declaration';
                Image = Import;

                trigger OnAction()
                var
                    NFBImportDeclaration: Record "NFB Import Declaration";
                begin
                    NFBImportDeclaration.SetRange("Table ID", Database::"NFB Document Line");
                    NFBImportDeclaration.SetRange("Document No.", Rec."Document No.");
                    NFBImportDeclaration.SetRange("Line No.", Rec."Line No.");
                    Page.Run(Page::"NFB Import Declarations", NFBImportDeclaration);
                end;
            }
        }
    }
}
