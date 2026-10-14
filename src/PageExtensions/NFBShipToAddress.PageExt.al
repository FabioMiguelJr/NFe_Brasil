pageextension 50102 "NFB Ship-to Address" extends "Ship-to Address"
{
    layout
    {
        addlast(Content)
        {
            group(NFBFiscal)
            {
                Caption = 'Fiscal (NF-e)';
                field("NFB CPF/CNPJ"; Rec."NFB CPF/CNPJ") { ApplicationArea = All; }
                field("NFB IE"; Rec."NFB IE") { ApplicationArea = All; }
                field("NFB Address No."; Rec."NFB Address No.") { ApplicationArea = All; }
                field("NFB District"; Rec."NFB District") { ApplicationArea = All; }
                field("NFB Municipality Code"; Rec."NFB Municipality Code") { ApplicationArea = All; }
                field("NFB UF"; Rec."NFB UF") { ApplicationArea = All; }
            }
        }
    }
}
