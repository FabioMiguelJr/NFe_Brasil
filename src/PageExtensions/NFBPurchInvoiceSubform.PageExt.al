pageextension 50126 "NFB Purch. Invoice Subform" extends "Purch. Invoice Subform"
{
    layout
    {
        addafter(Description)
        {
            field("NFB CFOP"; Rec."NFB CFOP") { ApplicationArea = All; }
            field("NFB Tax Rule Code"; Rec."NFB Tax Rule Code") { ApplicationArea = All; }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(NFBImportDeclaration)
            {
                ApplicationArea = All;
                Caption = 'Import Declaration (DI)';
                Image = Import;

                trigger OnAction()
                var
                    NFBImportDeclaration: Record "NFB Import Declaration";
                begin
                    NFBImportDeclaration.SetRange("Table ID", Database::"Purchase Line");
                    NFBImportDeclaration.SetRange("Document Type", Rec."Document Type".AsInteger());
                    NFBImportDeclaration.SetRange("Document No.", Rec."Document No.");
                    NFBImportDeclaration.SetRange("Line No.", Rec."Line No.");
                    Page.Run(Page::"NFB Import Declarations", NFBImportDeclaration);
                end;
            }
        }
    }
}
