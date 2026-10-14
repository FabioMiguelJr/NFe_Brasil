pageextension 50210 "NFB Sales Order" extends "Sales Order"
{
    layout
    {
        addlast(General)
        {
            group(NFBFiscal)
            {
                Caption = 'NF-e';
                field("NFB Operation Type"; Rec."NFB Operation Type") { ApplicationArea = All; }
                field("NFB Nature of Operation"; Rec."NFB Nature of Operation") { ApplicationArea = All; }
                field("NFB Purpose"; Rec."NFB Purpose") { ApplicationArea = All; }
                field("NFB Presence Indicator"; Rec."NFB Presence Indicator") { ApplicationArea = All; }
                field("NFB Final Consumer"; Rec."NFB Final Consumer") { ApplicationArea = All; }
                field("NFB Freight Mode"; Rec."NFB Freight Mode") { ApplicationArea = All; }
                field("NFB Referenced Key"; Rec."NFB Referenced Key") { ApplicationArea = All; }
                field("NFB Additional Info"; Rec."NFB Additional Info") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            group(NFBActions)
            {
                Caption = 'NF-e';
                Image = ElectronicDoc;
                action(NFBCalculateTaxes)
                {
                    ApplicationArea = All;
                    Caption = 'Calculate NF-e Taxes';
                    Image = CalculateSalesTax;
                    ToolTip = 'Calculates ICMS, IPI, PIS, COFINS, IBS and CBS for the lines using the NF-e tax rules. Taxes are calculated again on posting.';

                    trigger OnAction()
                    var
                        NFBTaxEngine: Codeunit "NFB Tax Engine";
                    begin
                        CurrPage.SaveRecord();
                        NFBTaxEngine.CalculateSalesDocument(Rec);
                        Commit();
                        ShowNFBTaxLines();
                    end;
                }
                action(NFBTaxLines)
                {
                    ApplicationArea = All;
                    Caption = 'NF-e Taxes';
                    Image = TaxDetail;

                    trigger OnAction()
                    begin
                        ShowNFBTaxLines();
                    end;
                }
            }
        }
    }

    local procedure ShowNFBTaxLines()
    var
        NFBTaxLine: Record "NFB Tax Line";
    begin
        NFBTaxLine.SetRange("Table ID", Database::"Sales Line");
        NFBTaxLine.SetRange("Document Type", Rec."Document Type".AsInteger());
        NFBTaxLine.SetRange("Document No.", Rec."No.");
        Page.Run(Page::"NFB Tax Lines", NFBTaxLine);
    end;
}
