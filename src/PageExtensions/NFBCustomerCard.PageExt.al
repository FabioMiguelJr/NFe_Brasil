pageextension 50101 "NFB Customer Card" extends "Customer Card"
{
    layout
    {
        addlast(Content)
        {
            group(NFBFiscal)
            {
                Caption = 'Fiscal (NF-e)';
                field("NFB Person Type"; Rec."NFB Person Type") { ApplicationArea = All; }
                field("NFB CPF/CNPJ"; Rec."NFB CPF/CNPJ") { ApplicationArea = All; }
                field("NFB Foreign Id"; Rec."NFB Foreign Id") { ApplicationArea = All; }
                field("NFB IE Indicator"; Rec."NFB IE Indicator") { ApplicationArea = All; }
                field("NFB IE"; Rec."NFB IE") { ApplicationArea = All; }
                field("NFB Final Consumer"; Rec."NFB Final Consumer") { ApplicationArea = All; }
                field("NFB SUFRAMA"; Rec."NFB SUFRAMA") { ApplicationArea = All; }
                field("NFB XML E-Mail"; Rec."NFB XML E-Mail") { ApplicationArea = All; }
                field("NFB Address No."; Rec."NFB Address No.") { ApplicationArea = All; }
                field("NFB District"; Rec."NFB District") { ApplicationArea = All; }
                field("NFB Municipality Code"; Rec."NFB Municipality Code") { ApplicationArea = All; }
                field("NFB UF"; Rec."NFB UF") { ApplicationArea = All; }
            }
        }
    }
}
