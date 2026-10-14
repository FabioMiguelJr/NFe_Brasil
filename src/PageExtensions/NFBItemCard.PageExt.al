pageextension 50105 "NFB Item Card" extends "Item Card"
{
    layout
    {
        addlast(Content)
        {
            group(NFBFiscal)
            {
                Caption = 'Fiscal (NF-e)';
                field("NFB NCM"; Rec."NFB NCM") { ApplicationArea = All; }
                field("NFB CEST"; Rec."NFB CEST") { ApplicationArea = All; }
                field("NFB Ex TIPI"; Rec."NFB Ex TIPI") { ApplicationArea = All; }
                field("NFB Origin"; Rec."NFB Origin") { ApplicationArea = All; }
                field("NFB GTIN"; Rec."NFB GTIN") { ApplicationArea = All; }
                field("NFB Taxable Unit"; Rec."NFB Taxable Unit") { ApplicationArea = All; }
                field("NFB Taxable Unit Factor"; Rec."NFB Taxable Unit Factor") { ApplicationArea = All; }
                field("NFB Tax Group"; Rec."NFB Tax Group") { ApplicationArea = All; }
                field("NFB cClassTrib"; Rec."NFB cClassTrib") { ApplicationArea = All; }
            }
        }
    }
}
