page 50119 "NFB Setup"
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
            group(XmlGroup)
            {
                Caption = 'XML';
                field("Validate XSD"; Rec."Validate XSD") { ApplicationArea = All; ToolTip = 'Checks each generated XML against the SEFAZ schemas imported in XSD Schemas.'; }
                field("Include IBS/CBS Group"; Rec."Include IBS/CBS Group") { ApplicationArea = All; ToolTip = 'Adds the IBS/CBS groups of NT 2025.002 to the XML. Turn it off if the SEFAZ of your state does not accept them yet.'; }
                field("Software Version"; Rec."Software Version") { ApplicationArea = All; ToolTip = 'Version of the issuing application (verProc).'; }
                field("UTC Offset"; Rec."UTC Offset") { ApplicationArea = All; ToolTip = 'Time zone of the issue date in the XML, for example -03:00.'; }
            }
            group(TechResponsible)
            {
                Caption = 'Technical Responsible (infRespTec)';
                field("Resp. Tech. CNPJ"; Rec."Resp. Tech. CNPJ") { ApplicationArea = All; }
                field("Resp. Tech. Contact"; Rec."Resp. Tech. Contact") { ApplicationArea = All; }
                field("Resp. Tech. E-Mail"; Rec."Resp. Tech. E-Mail") { ApplicationArea = All; }
                field("Resp. Tech. Phone"; Rec."Resp. Tech. Phone") { ApplicationArea = All; }
            }
            group(Provider)
            {
                Caption = 'PlugNotas';
                field("Use PlugNotas Sandbox"; Rec."Use PlugNotas Sandbox") { ApplicationArea = All; }
                field("Provider URL"; Rec."Provider URL") { ApplicationArea = All; ToolTip = 'Specifies a different PlugNotas address. Leave it blank to use the sandbox or the real API according to Use PlugNotas Sandbox.'; }
                field(ApiKeyField; ApiKey)
                {
                    ApplicationArea = All;
                    Caption = 'API Key';
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the PlugNotas API key (x-api-key). It is kept in isolated storage, not in the table. In the sandbox, when it is blank, the public test key is used.';

                    trigger OnValidate()
                    var
                        NFBPlugNotasClient: Codeunit "NFB PlugNotas Client";
                    begin
                        if ApiKey = MaskedKey(true) then
                            exit;
                        NFBPlugNotasClient.SetApiKey(ApiKey);
                        ApiKey := MaskedKey(NFBPlugNotasClient.HasApiKey());
                    end;
                }
                field("Status Query Minutes"; Rec."Status Query Minutes") { ApplicationArea = All; }
            }
            group(Settlement)
            {
                Caption = 'Tax Settlement';
                field("Tax Settlement Nos."; Rec."Tax Settlement Nos.") { ApplicationArea = All; }
                field("Settlement Jnl. Template"; Rec."Settlement Jnl. Template") { ApplicationArea = All; }
                field("Settlement Jnl. Batch"; Rec."Settlement Jnl. Batch") { ApplicationArea = All; }
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
            action(XSDSchemas) { ApplicationArea = All; Caption = 'XSD Schemas'; Image = XMLSetup; RunObject = page "NFB XSD Schemas"; }
            action(DocumentFiles) { ApplicationArea = All; Caption = 'NF-e Files'; Image = Documents; RunObject = page "NFB Document Files"; }
            action(DocumentEvents) { ApplicationArea = All; Caption = 'NF-e Events'; Image = History; RunObject = page "NFB Document Events"; }
            action(TaxDueDates) { ApplicationArea = All; Caption = 'Tax Due Date Setup'; Image = DueDate; RunObject = page "NFB Tax Due Date Setup"; }
            action(TaxSettlements) { ApplicationArea = All; Caption = 'Tax Settlements'; Image = SettleOpenTransactions; RunObject = page "NFB Tax Settlements"; }
        }
        area(Processing)
        {
            action(TestConnection)
            {
                ApplicationArea = All;
                Caption = 'Test Connection';
                Image = TestDatabase;
                ToolTip = 'Checks that Business Central reaches the authorizer of the issue mode and that the company is registered there.';

                trigger OnAction()
                var
                    NFBProviderMgt: Codeunit "NFB Provider Mgt";
                begin
                    CurrPage.SaveRecord();
                    Commit();
                    NFBProviderMgt.TestConnection();
                end;
            }
            action(CreateJobQueueEntry)
            {
                ApplicationArea = All;
                Caption = 'Create Status Query Job';
                Image = Job;
                ToolTip = 'Creates a recurring job queue entry that queries the sent NF-e and the pending events.';

                trigger OnAction()
                var
                    NFBProviderMgt: Codeunit "NFB Provider Mgt";
                begin
                    NFBProviderMgt.CreateJobQueueEntry(Rec."Status Query Minutes");
                end;
            }
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
    var
        NFBPlugNotasClient: Codeunit "NFB PlugNotas Client";
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
        ApiKey := MaskedKey(NFBPlugNotasClient.HasApiKey());
    end;

    local procedure MaskedKey(HasKey: Boolean): Text
    begin
        if HasKey then
            exit('********');
        exit('');
    end;

    var
        ApiKey: Text;
}
