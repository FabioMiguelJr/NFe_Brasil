codeunit 50207 "NFB Install"
{
    // Default data for an issuer in RJ, regime normal, Lucro Presumido.
    // Rates and CSTs are starting points and must be reviewed by the company's accountant.
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
        InsertDefaults();
    end;

    procedure InsertDefaults()
    begin
        InsertSetup();
        InsertTaxPostingSetup();
        InsertCFOPs();
        InsertcClassTrib();
        InsertMunicipalities();
        InsertOperationTypes();
        InsertTaxRules();
    end;

    local procedure InsertSetup()
    var
        NFBSetup: Record "NFB Setup";
        NFBSeries: Record "NFB Series";
    begin
        if not NFBSetup.Get() then begin
            NFBSetup.Init();
            NFBSetup.Environment := NFBSetup.Environment::Homologation;
            NFBSetup."Issue Mode" := NFBSetup."Issue Mode"::"File Only";
            NFBSetup."Default Series" := 1;
            NFBSetup."Sales Operation Type" := 'VENDA';
            NFBSetup."Sales Return Operation Type" := 'DEVOL-VENDA';
            NFBSetup."Purchase Operation Type" := 'COMPRA';
            NFBSetup."Purch. Return Operation Type" := 'DEVOL-COMPRA';
            NFBSetup."Transfer Operation Type" := 'TRANSF';
            NFBSetup.Insert();
        end;
        if not NFBSeries.Get('55', 1) then begin
            NFBSeries.Init();
            NFBSeries.Model := '55';
            NFBSeries.Series := 1;
            NFBSeries.Description := 'NF-e série 1';
            NFBSeries.Insert();
        end;
    end;

    local procedure InsertTaxPostingSetup()
    var
        NFBTaxPostingSetup: Record "NFB Tax Posting Setup";
        Ordinal: Integer;
    begin
        foreach Ordinal in Enum::"NFB Tax Type".Ordinals() do
            if Ordinal <> 0 then
                if not NFBTaxPostingSetup.Get(Enum::"NFB Tax Type".FromInteger(Ordinal)) then begin
                    NFBTaxPostingSetup.Init();
                    NFBTaxPostingSetup."Tax Type" := Enum::"NFB Tax Type".FromInteger(Ordinal);
                    NFBTaxPostingSetup.Insert(true);
                end;
    end;

    local procedure InsertCFOPs()
    begin
        InsertCFOP('1102', 'Compra para comercialização', false);
        InsertCFOP('2102', 'Compra para comercialização (interestadual)', false);
        InsertCFOP('3102', 'Compra para comercialização (importação)', false);
        InsertCFOP('1152', 'Transferência para comercialização', false);
        InsertCFOP('1202', 'Devolução de venda de mercadoria adquirida de terceiros', true);
        InsertCFOP('2202', 'Devolução de venda de mercadoria adquirida de terceiros (interestadual)', true);
        InsertCFOP('3202', 'Devolução de venda de mercadoria adquirida de terceiros (exterior)', true);
        InsertCFOP('5101', 'Venda de produção do estabelecimento', false);
        InsertCFOP('6101', 'Venda de produção do estabelecimento (interestadual)', false);
        InsertCFOP('7101', 'Venda de produção do estabelecimento (exterior)', false);
        InsertCFOP('5102', 'Venda de mercadoria adquirida de terceiros', false);
        InsertCFOP('6102', 'Venda de mercadoria adquirida de terceiros (interestadual)', false);
        InsertCFOP('7102', 'Venda de mercadoria adquirida de terceiros (exterior)', false);
        InsertCFOP('5152', 'Transferência de mercadoria adquirida de terceiros', false);
        InsertCFOP('5202', 'Devolução de compra para comercialização', true);
        InsertCFOP('6202', 'Devolução de compra para comercialização (interestadual)', true);
        InsertCFOP('7202', 'Devolução de compra para comercialização (exterior)', true);
        InsertCFOP('5901', 'Remessa para industrialização por encomenda', false);
        InsertCFOP('6901', 'Remessa para industrialização por encomenda (interestadual)', false);
        InsertCFOP('5910', 'Remessa em bonificação, doação ou brinde', false);
        InsertCFOP('6910', 'Remessa em bonificação, doação ou brinde (interestadual)', false);
        InsertCFOP('5912', 'Remessa de mercadoria para demonstração', false);
        InsertCFOP('6912', 'Remessa de mercadoria para demonstração (interestadual)', false);
        InsertCFOP('5915', 'Remessa de mercadoria para conserto ou reparo', false);
        InsertCFOP('6915', 'Remessa de mercadoria para conserto ou reparo (interestadual)', false);
        InsertCFOP('5917', 'Remessa de mercadoria em consignação mercantil', false);
        InsertCFOP('6917', 'Remessa de mercadoria em consignação mercantil (interestadual)', false);
        InsertCFOP('5949', 'Outra saída de mercadoria não especificada', false);
        InsertCFOP('6949', 'Outra saída de mercadoria não especificada (interestadual)', false);
    end;

    local procedure InsertcClassTrib()
    var
        NFBcClassTrib: Record "NFB cClassTrib";
    begin
        if NFBcClassTrib.Get('000001') then
            exit;
        NFBcClassTrib.Init();
        NFBcClassTrib.Code := '000001';
        NFBcClassTrib.CST := '000';
        NFBcClassTrib.Description := 'Situações tributadas integralmente pelo IBS e CBS';
        NFBcClassTrib.Insert();
    end;

    local procedure InsertMunicipalities()
    var
        NFBMunicipality: Record "NFB Municipality";
    begin
        if NFBMunicipality.Get('3304557') then
            exit;
        NFBMunicipality.Init();
        NFBMunicipality.Validate(Code, '3304557');
        NFBMunicipality.Name := 'Rio de Janeiro';
        NFBMunicipality.UF := 'RJ';
        NFBMunicipality.Insert();
    end;

    local procedure InsertOperationTypes()
    var
        Direction: Enum "NFB Direction";
        Purpose: Enum "NFB Purpose";
    begin
        InsertOperationType('VENDA', 'Venda de mercadoria', 'Venda de mercadoria', Direction::Outbound, Purpose::Normal, '5102', '6102', '7102', true, true, false);
        InsertOperationType('VENDA-PROD', 'Venda de produção própria', 'Venda de produção do estabelecimento', Direction::Outbound, Purpose::Normal, '5101', '6101', '7101', true, true, false);
        InsertOperationType('EXPORTACAO', 'Venda para o exterior', 'Venda de mercadoria - exportação', Direction::Outbound, Purpose::Normal, '', '', '7102', true, true, false);
        InsertOperationType('DEVOL-VENDA', 'Devolução de venda', 'Devolução de venda', Direction::Inbound, Purpose::Return, '1202', '2202', '3202', true, true, true);
        InsertOperationType('COMPRA', 'Compra de fornecedor nacional (sem emissão)', 'Compra para comercialização', Direction::Inbound, Purpose::Normal, '1102', '2102', '3102', false, true, false);
        InsertOperationType('IMPORTACAO', 'Importação (NF-e de entrada própria)', 'Compra para comercialização - importação', Direction::Inbound, Purpose::Normal, '', '', '3102', true, true, false);
        InsertOperationType('DEVOL-COMPRA', 'Devolução de compra', 'Devolução de compra para comercialização', Direction::Outbound, Purpose::Return, '5202', '6202', '7202', true, true, true);
        InsertOperationType('TRANSF', 'Transferência entre estabelecimentos', 'Transferência de mercadoria', Direction::Outbound, Purpose::Normal, '5152', '', '', true, false, false);
        InsertOperationType('REM-INDUSTR', 'Remessa para industrialização', 'Remessa para industrialização por encomenda', Direction::Outbound, Purpose::Normal, '5901', '6901', '', true, false, false);
        InsertOperationType('REM-BONIF', 'Remessa em bonificação', 'Remessa em bonificação, doação ou brinde', Direction::Outbound, Purpose::Normal, '5910', '6910', '', true, true, false);
        InsertOperationType('REM-DEMO', 'Remessa para demonstração', 'Remessa de mercadoria para demonstração', Direction::Outbound, Purpose::Normal, '5912', '6912', '', true, false, false);
        InsertOperationType('REM-CONSERTO', 'Remessa para conserto', 'Remessa para conserto ou reparo', Direction::Outbound, Purpose::Normal, '5915', '6915', '', true, false, false);
        InsertOperationType('REM-CONSIG', 'Remessa em consignação', 'Remessa em consignação mercantil', Direction::Outbound, Purpose::Normal, '5917', '6917', '', true, true, false);
        InsertOperationType('COMPLEMENTAR', 'NF-e complementar', 'Complemento de valor ou imposto', Direction::Outbound, Purpose::Complementary, '5102', '6102', '7102', true, true, true);
        InsertOperationType('AJUSTE', 'NF-e de ajuste', 'Ajuste', Direction::Outbound, Purpose::Adjustment, '5949', '6949', '', true, false, true);
    end;

    local procedure InsertTaxRules()
    begin
        // Example rules (RJ, Lucro Presumido, 2026). ICMS RJ 18% + FCP 2%; interstate 12% (7% to N/NE/CO/ES; 4% for imported goods).
        // PIS/COFINS cumulative 0.65% / 3%. IBS/CBS 2026 test rates: CBS 0.9%, IBS UF 0.1%.
        InsertTaxRule('VENDA-INT', 'Venda interna RJ', 'VENDA', 1, '00', 18, 2, 0, '01', 0.65, '01', 3);
        InsertTaxRule('VENDA-INTER', 'Venda interestadual', 'VENDA', 2, '00', 12, 0, 0, '01', 0.65, '01', 3);
        InsertTaxRule('EXPORT', 'Exportação (não incidência)', 'EXPORTACAO', 3, '41', 0, 0, 0, '08', 0, '08', 0);
        InsertTaxRule('DEVOL-VENDA', 'Devolução de venda interna', 'DEVOL-VENDA', 0, '00', 18, 2, 0, '01', 0.65, '01', 3);
        InsertTaxRule('COMPRA-INT', 'Compra interna RJ (crédito de ICMS)', 'COMPRA', 1, '00', 18, 0, 0, '70', 0, '70', 0);
        InsertTaxRule('COMPRA-INTER', 'Compra interestadual (crédito de ICMS)', 'COMPRA', 2, '00', 12, 0, 0, '70', 0, '70', 0);
        InsertTaxRule('IMPORTACAO', 'Importação', 'IMPORTACAO', 3, '00', 18, 2, 0, '70', 0, '70', 0);
        InsertTaxRule('DEVOL-COMPRA', 'Devolução de compra', 'DEVOL-COMPRA', 0, '00', 18, 0, 0, '49', 0, '49', 0);
        InsertTaxRule('TRANSF', 'Transferência (LC 204/2023, sem ICMS)', 'TRANSF', 0, '41', 0, 0, 0, '49', 0, '49', 0);
        InsertTaxRule('REMESSA', 'Remessas sem tributação', '', 0, '41', 0, 0, 0, '49', 0, '49', 0);
    end;

    local procedure InsertCFOP(CfopCode: Code[4]; Description: Text[250]; IsReturn: Boolean)
    var
        NFBCFOP: Record "NFB CFOP";
    begin
        if NFBCFOP.Get(CfopCode) then
            exit;
        NFBCFOP.Init();
        NFBCFOP.Validate(Code, CfopCode);
        NFBCFOP.Description := Description;
        NFBCFOP."Is Return" := IsReturn;
        NFBCFOP.Insert();
    end;

    local procedure InsertOperationType(OperationCode: Code[20]; Description: Text[100]; NatureOfOperation: Text[60]; Direction: Enum "NFB Direction"; Purpose: Enum "NFB Purpose"; CfopInternal: Code[4]; CfopInterstate: Code[4]; CfopExterior: Code[4]; IssueNFe: Boolean; PostTaxes: Boolean; RequiresReference: Boolean)
    var
        NFBOperationType: Record "NFB Operation Type";
    begin
        if NFBOperationType.Get(OperationCode) then
            exit;
        NFBOperationType.Init();
        NFBOperationType.Code := OperationCode;
        NFBOperationType.Description := Description;
        NFBOperationType."Nature of Operation" := NatureOfOperation;
        NFBOperationType.Direction := Direction;
        NFBOperationType.Purpose := Purpose;
        NFBOperationType."CFOP Internal" := CfopInternal;
        NFBOperationType."CFOP Interstate" := CfopInterstate;
        NFBOperationType."CFOP Exterior" := CfopExterior;
        NFBOperationType."Issue NF-e" := IssueNFe;
        NFBOperationType."Calculate Taxes" := true;
        NFBOperationType."Post Taxes" := PostTaxes;
        NFBOperationType."Requires Reference" := RequiresReference;
        NFBOperationType.Insert();
    end;

    local procedure InsertTaxRule(RuleCode: Code[20]; Description: Text[100]; OperationType: Code[20]; Destination: Option; IcmsCst: Code[3]; IcmsRate: Decimal; FcpRate: Decimal; IpiRate: Decimal; PisCst: Code[2]; PisRate: Decimal; CofinsCst: Code[2]; CofinsRate: Decimal)
    var
        NFBTaxRule: Record "NFB Tax Rule";
    begin
        if NFBTaxRule.Get(RuleCode) then
            exit;
        NFBTaxRule.Init();
        NFBTaxRule.Code := RuleCode;
        NFBTaxRule.Description := Description;
        NFBTaxRule."Operation Type" := OperationType;
        NFBTaxRule.Destination := Destination;
        NFBTaxRule."ICMS CST" := IcmsCst;
        NFBTaxRule."ICMS %" := IcmsRate;
        NFBTaxRule."FCP %" := FcpRate;
        NFBTaxRule."Use NCM IPI %" := false;
        NFBTaxRule."IPI %" := IpiRate;
        NFBTaxRule."PIS CST" := PisCst;
        NFBTaxRule."PIS %" := PisRate;
        NFBTaxRule."COFINS CST" := CofinsCst;
        NFBTaxRule."COFINS %" := CofinsRate;
        if IcmsCst = '00' then begin
            NFBTaxRule."IBS/CBS CST" := '000';
            NFBTaxRule.cClassTrib := '000001';
            NFBTaxRule."IBS UF %" := 0.1;
            NFBTaxRule."IBS Mun. %" := 0;
            NFBTaxRule."CBS %" := 0.9;
        end;
        NFBTaxRule.Insert();
    end;
}
