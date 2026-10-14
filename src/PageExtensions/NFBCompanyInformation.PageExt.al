pageextension 50100 "NFB Company Information" extends "Company Information"
{
    layout
    {
        addlast(Content)
        {
            group(NFBFiscal)
            {
                Caption = 'Fiscal (NF-e)';
                field("NFB CNPJ"; Rec."NFB CNPJ") { ApplicationArea = All; }
                field("NFB IE"; Rec."NFB IE") { ApplicationArea = All; }
                field("NFB IM"; Rec."NFB IM") { ApplicationArea = All; }
                field("NFB CNAE"; Rec."NFB CNAE") { ApplicationArea = All; }
                field("NFB Tax Regime"; Rec."NFB Tax Regime") { ApplicationArea = All; }
                field("NFB ST IE"; Rec."NFB ST IE") { ApplicationArea = All; }
                field("NFB Address No."; Rec."NFB Address No.") { ApplicationArea = All; }
                field("NFB District"; Rec."NFB District") { ApplicationArea = All; }
                field("NFB Municipality Code"; Rec."NFB Municipality Code") { ApplicationArea = All; }
                field("NFB UF"; Rec."NFB UF") { ApplicationArea = All; }
            }
        }
    }
}
