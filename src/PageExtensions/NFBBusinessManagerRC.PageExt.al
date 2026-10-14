pageextension 50140 "NFB Business Manager RC" extends "Business Manager Role Center"
{
    actions
    {
        addlast(sections)
        {
            group(NFBSetupGroup)
            {
                Caption = 'NF-e Setup';
                ToolTip = 'NF-e configuration pages.';

                action(NFBSetup)
                {
                    ApplicationArea = All;
                    Caption = 'NF-e Setup';
                    ToolTip = 'Opens the general NF-e setup: environment, issue mode, series and default operation types.';
                    RunObject = page "NFB Setup";
                }
                action(NFBSeries)
                {
                    ApplicationArea = All;
                    Caption = 'NF-e Series';
                    ToolTip = 'Opens the NF-e series and their number series.';
                    RunObject = page "NFB Series";
                }
                action(NFBOperationTypes)
                {
                    ApplicationArea = All;
                    Caption = 'Operation Types';
                    ToolTip = 'Opens the operation types (nature of operation, CFOP and purpose).';
                    RunObject = page "NFB Operation Types";
                }
                action(NFBTaxRules)
                {
                    ApplicationArea = All;
                    Caption = 'Tax Rules';
                    ToolTip = 'Opens the tax rules with rates and CST for each tax.';
                    RunObject = page "NFB Tax Rules";
                }
                action(NFBTaxPostingSetup)
                {
                    ApplicationArea = All;
                    Caption = 'Tax Posting Setup';
                    ToolTip = 'Opens the G/L accounts used to post each tax.';
                    RunObject = page "NFB Tax Posting Setup";
                }
                action(NFBMunicipalities)
                {
                    ApplicationArea = All;
                    Caption = 'Municipalities (IBGE)';
                    ToolTip = 'Opens the IBGE municipality codes.';
                    RunObject = page "NFB Municipalities";
                }
                action(NFBNCM)
                {
                    ApplicationArea = All;
                    Caption = 'NCM';
                    ToolTip = 'Opens the NCM list.';
                    RunObject = page "NFB NCM List";
                }
                action(NFBCFOP)
                {
                    ApplicationArea = All;
                    Caption = 'CFOP';
                    ToolTip = 'Opens the CFOP list.';
                    RunObject = page "NFB CFOP List";
                }
                action(NFBcClassTrib)
                {
                    ApplicationArea = All;
                    Caption = 'cClassTrib (IBS/CBS)';
                    ToolTip = 'Opens the IBS/CBS tax classifications.';
                    RunObject = page "NFB cClassTrib List";
                }
                action(NFBXSDSchemas)
                {
                    ApplicationArea = All;
                    Caption = 'XSD Schemas';
                    ToolTip = 'Opens the SEFAZ schemas used to check the generated XML.';
                    RunObject = page "NFB XSD Schemas";
                }
                action(NFBDocumentEvents)
                {
                    ApplicationArea = All;
                    Caption = 'NF-e Events';
                    ToolTip = 'Opens the cancellation and correction letter events.';
                    RunObject = page "NFB Document Events";
                }
            }
        }
    }
}
