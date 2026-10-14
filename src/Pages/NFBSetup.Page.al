page 50200 "NFB Setup"
{
    PageType = Card;
    SourceTable = "NFB Setup";
    Caption = 'NF-e Setup';
    ApplicationArea = All;
    UsageCategory = Administration;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field(Environment; Rec.Environment) { ApplicationArea = All; ToolTip = 'Homologation sends to the SEFAZ test environment; documents there have no fiscal value.'; }
                field("Issue Mode"; Rec."Issue Mode") { ApplicationArea = All; ToolTip = 'How the NF-e is transmitted: directly to SEFAZ, through PlugNotas, or exported as a file for another system.'; }
                field("Layout Version"; Rec."Layout Version") { ApplicationArea = All; }
                field("Emission Type"; Rec."Emission Type") { ApplicationArea = All; ToolTip = '1 = normal. 6 = SVC-AN contingency.'; }
                field("Default Series"; Rec."Default Series") { ApplicationArea = All; }
                field("Document Nos."; Rec."Document Nos.") { ApplicationArea = All; ToolTip = 'Internal numbering of the fiscal documents. The NF-e number (nNF) comes from the series.'; }
                field("Auto Create Document"; Rec."Auto Create Document") { ApplicationArea = All; }
            }
            group(Taxes)
            {
                Caption = 'Taxes';
                field("Exclude ICMS from PIS/COFINS"; Rec."Exclude ICMS from PIS/COFINS") { ApplicationArea = All; }
                field("Exclude Taxes from IBS/CBS"; Rec."Exclude Taxes from IBS/CBS") { ApplicationArea = All; }
            }
            group(Defaults)
            {
                Caption = 'Default Operation Types';
                field("Sales Operation Type"; Rec."Sales Operation Type") { ApplicationArea = All; }
                field("Sales Return Operation Type"; Rec."Sales Return Operation Type") { ApplicationArea = All; }
                field("Purchase Operation Type"; Rec."Purchase Operation Type") { ApplicationArea = All; }
                field("Purch. Return Operation Type"; Rec."Purch. Return Operation Type") { ApplicationArea = All; }
                field("Transfer Operation Type"; Rec."Transfer Operation Type") { ApplicationArea = All; }
            }
            group(Provider)
            {
                Caption = 'Provider';
                field("Provider URL"; Rec."Provider URL") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(Series) { ApplicationArea = All; Caption = 'Series'; Image = NumberSetup; RunObject = page "NFB Series"; }
            action(OperationTypes) { ApplicationArea = All; Caption = 'Operation Types'; Image = Setup; RunObject = page "NFB Operation Types"; }
            action(TaxRules) { ApplicationArea = All; Caption = 'Tax Rules'; Image = TaxSetup; RunObject = page "NFB Tax Rules"; }
            action(TaxPosting) { ApplicationArea = All; Caption = 'Tax Posting Setup'; Image = GeneralPostingSetup; RunObject = page "NFB Tax Posting Setup"; }
            action(Municipalities) { ApplicationArea = All; Caption = 'Municipalities (IBGE)'; Image = List; RunObject = page "NFB Municipalities"; }
            action(NCM) { ApplicationArea = All; Caption = 'NCM'; Image = List; RunObject = page "NFB NCM List"; }
            action(CFOP) { ApplicationArea = All; Caption = 'CFOP'; Image = List; RunObject = page "NFB CFOP List"; }
            action(cClassTrib) { ApplicationArea = All; Caption = 'cClassTrib'; Image = List; RunObject = page "NFB cClassTrib List"; }
        }
        area(Processing)
        {
            action(LoadDefaults)
            {
                ApplicationArea = All;
                Caption = 'Load Default Data';
                Image = Setup;
                ToolTip = 'Creates the default series, CFOPs, operation types and example tax rules for RJ. Existing records are kept.';

                trigger OnAction()
                var
                    NFBInstall: Codeunit "NFB Install";
                begin
                    NFBInstall.InsertDefaults();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}
