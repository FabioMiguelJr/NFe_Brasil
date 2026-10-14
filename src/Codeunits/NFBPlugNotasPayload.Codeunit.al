codeunit 50121 "NFB PlugNotas Payload"
{
    // Converts the fiscal document into the NF-e JSON of the TecnoSpeed PlugNotas API (POST /nfe).
    // Field names follow the official TecnoSpeed samples for the tax reform (github.com/tecnospeed/Arquivos_RTC)
    // and the PlugNotas documentation. The body of POST /nfe is an array with one object per NF-e.

    var
        NFBSetup: Record "NFB Setup";
        NFBXMLBuilder: Codeunit "NFB XML Builder";
        NFBValidation: Codeunit "NFB Validation";
        HomologationNameTxt: Label 'NF-E EMITIDA EM AMBIENTE DE HOMOLOGACAO - SEM VALOR FISCAL', Locked = true;
        NoLinesErr: Label 'NF-e %1 has no lines.', Comment = '%1 = document no.';
        SimplesNotSupportedErr: Label 'The issuer tax regime is Simples Nacional (CSOSN), which this version does not generate.';

    /// <summary>
    /// Builds the body of POST /nfe (an array with this NF-e) and writes it, UTF-8 encoded, to TempBlob.
    /// </summary>
    procedure BuildJson(var NFBDocumentHeader: Record "NFB Document Header"; var TempBlob: Codeunit "Temp Blob")
    var
        Body: JsonArray;
        OutStr: OutStream;
    begin
        Body.Add(BuildDocument(NFBDocumentHeader));
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        Body.WriteTo(OutStr);
    end;

    procedure BuildDocument(var NFBDocumentHeader: Record "NFB Document Header") Doc: JsonObject
    var
        Config: JsonObject;
        EmissionType: Integer;
    begin
        NFBSetup.Get();
        if NFBDocumentHeader."Issuer CRT" in [NFBDocumentHeader."Issuer CRT"::"Simples Nacional", NFBDocumentHeader."Issuer CRT"::MEI] then
            Error(SimplesNotSupportedErr);
        EmissionType := NFBDocumentHeader."Emission Type";
        if EmissionType = 0 then
            EmissionType := 1;

        Doc.Add('idIntegracao', NFBDocumentHeader."No.");
        Doc.Add('versaoManual', '4.00');
        Doc.Add('natureza', NFBXMLBuilder.Clean(NFBDocumentHeader."Nature of Operation", 60));
        Doc.Add('modelo', DefaultText(NFBDocumentHeader.Model, '55'));
        Doc.Add('serie', Format(NFBDocumentHeader.Series));
        Doc.Add('numero', NFBDocumentHeader."NF No.");
        Doc.Add('codigo', NFBDocumentHeader."Numeric Code");
        Doc.Add('dataEmissao', NFBXMLBuilder.FormatDateTimeTZ(NFBDocumentHeader."Issue DateTime"));
        if NFBDocumentHeader."Exit DateTime" <> 0DT then
            Doc.Add('dataSaidaEntrada', NFBXMLBuilder.FormatDateTimeTZ(NFBDocumentHeader."Exit DateTime"));
        Doc.Add('saida', NFBDocumentHeader.Direction.AsInteger() = 1);
        Doc.Add('codigoIdentificacaoDestino', Format(NFBDocumentHeader."Destination Id".AsInteger()));
        Doc.Add('codigoMunicipioFatoGerador', NFBDocumentHeader."Taxable Event Municipality");
        Doc.Add('tipoImpressao', '1');
        Doc.Add('tipoEmissao', Format(EmissionType));
        Doc.Add('ambiente', Format(NFBDocumentHeader.Environment.AsInteger()));
        Doc.Add('finalidade', Format(NFBDocumentHeader.Purpose.AsInteger()));
        Doc.Add('consumidorFinal', NFBDocumentHeader."Final Consumer");
        Doc.Add('presencial', NFBDocumentHeader."Presence Indicator".AsInteger());
        if NFBDocumentHeader."Presence Indicator".AsInteger() in [2, 3, 4, 9] then
            Doc.Add('intermediador', '0');
        Doc.Add('versaoProcesso', DefaultText(NFBSetup."Software Version", 'NFB 1.0'));

        Config.Add('producao', NFBDocumentHeader.Environment = NFBDocumentHeader.Environment::Production);
        Doc.Add('config', Config);

        AddReferences(Doc, NFBDocumentHeader);
        AddIssuer(Doc, NFBDocumentHeader);
        AddRecipient(Doc, NFBDocumentHeader);
        AddItems(Doc, NFBDocumentHeader);
        AddTotal(Doc, NFBDocumentHeader);
        AddTransport(Doc, NFBDocumentHeader);
        AddBilling(Doc, NFBDocumentHeader);
        AddPayments(Doc, NFBDocumentHeader);
        AddOptText(Doc, 'informacoesComplementares', NFBXMLBuilder.Clean(NFBDocumentHeader."Additional Info", 5000));
        AddOptText(Doc, 'informacoesFisco', NFBXMLBuilder.Clean(NFBDocumentHeader."Fiscal Info", 2000));
        AddExport(Doc, NFBDocumentHeader);
        AddTechResponsible(Doc);
    end;

    local procedure AddReferences(var Doc: JsonObject; NFBDocumentHeader: Record "NFB Document Header")
    var
        NFBDocumentReference: Record "NFB Document Reference";
        Reference: JsonObject;
        Keys: JsonArray;
        KeyObject: JsonObject;
    begin
        NFBDocumentReference.SetRange("Document No.", NFBDocumentHeader."No.");
        NFBDocumentReference.SetFilter("Referenced Access Key", '<>%1', '');
        if not NFBDocumentReference.FindSet() then
            exit;
        repeat
            Clear(KeyObject);
            KeyObject.Add('chave', NFBDocumentReference."Referenced Access Key");
            Keys.Add(KeyObject);
        until NFBDocumentReference.Next() = 0;
        Reference.Add('nfe', Keys);
        Doc.Add('notaReferenciada', Reference);
    end;

    local procedure AddIssuer(var Doc: JsonObject; NFBDocumentHeader: Record "NFB Document Header")
    var
        Issuer: JsonObject;
    begin
        // PlugNotas takes the issuer's name and address from the company registered there.
        Issuer.Add('cpfCnpj', NFBValidation.OnlyDigits(NFBDocumentHeader."Issuer CNPJ"));
        Issuer.Add('inscricaoEstadual', NFBValidation.OnlyDigits(NFBDocumentHeader."Issuer IE"));
        Doc.Add('emitente', Issuer);
    end;

    local procedure AddRecipient(var Doc: JsonObject; NFBDocumentHeader: Record "NFB Document Header")
    var
        Recipient: JsonObject;
        Address: JsonObject;
        RecipientName: Text;
        IsForeign: Boolean;
    begin
        IsForeign := NFBDocumentHeader."Recipient Type" = NFBDocumentHeader."Recipient Type"::Foreign;
        if IsForeign then
            AddOptText(Recipient, 'idEstrangeiro', NFBDocumentHeader."Recipient Foreign Id")
        else
            Recipient.Add('cpfCnpj', NFBValidation.OnlyDigits(NFBDocumentHeader."Recipient CPF/CNPJ"));
        RecipientName := NFBXMLBuilder.Clean(NFBDocumentHeader."Recipient Name", 60);
        if NFBDocumentHeader.Environment = NFBDocumentHeader.Environment::Homologation then
            RecipientName := HomologationNameTxt;
        Recipient.Add('razaoSocial', RecipientName);
        Recipient.Add('indicadorInscricaoEstadual', NFBDocumentHeader."Recipient IE Indicator".AsInteger());
        if NFBDocumentHeader."Recipient IE Indicator" = NFBDocumentHeader."Recipient IE Indicator"::Contributor then
            Recipient.Add('inscricaoEstadual', NFBValidation.OnlyDigits(NFBDocumentHeader."Recipient IE"));
        AddOptText(Recipient, 'inscricaoSuframa', NFBDocumentHeader."Recipient SUFRAMA");
        AddOptText(Recipient, 'email', NFBXMLBuilder.Clean(NFBDocumentHeader."Recipient E-Mail", 60));
        AddPhone(Recipient, NFBDocumentHeader."Recipient Phone");

        Address.Add('logradouro', NFBXMLBuilder.Clean(NFBDocumentHeader."Recipient Address", 60));
        Address.Add('numero', DefaultText(NFBXMLBuilder.Clean(NFBDocumentHeader."Recipient Address No.", 60), 'S/N'));
        AddOptText(Address, 'complemento', NFBXMLBuilder.Clean(NFBDocumentHeader."Recipient Address 2", 60));
        if IsForeign then
            Address.Add('bairro', DefaultText(NFBXMLBuilder.Clean(NFBDocumentHeader."Recipient District", 60), 'EXTERIOR'))
        else
            Address.Add('bairro', NFBXMLBuilder.Clean(NFBDocumentHeader."Recipient District", 60));
        Address.Add('codigoCidade', NFBDocumentHeader."Recipient Municipality Code");
        Address.Add('descricaoCidade', NFBXMLBuilder.Clean(NFBDocumentHeader."Recipient City", 60));
        Address.Add('estado', NFBDocumentHeader."Recipient UF");
        if not IsForeign then
            AddOptText(Address, 'cep', NFBValidation.OnlyDigits(NFBDocumentHeader."Recipient Post Code"));
        Address.Add('codigoPais', DefaultText(NFBDocumentHeader."Recipient BACEN Code", '1058'));
        Address.Add('descricaoPais', DefaultText(NFBXMLBuilder.Clean(NFBDocumentHeader."Recipient Country", 60), 'BRASIL'));
        Recipient.Add('endereco', Address);
        Doc.Add('destinatario', Recipient);
    end;

    local procedure AddItems(var Doc: JsonObject; NFBDocumentHeader: Record "NFB Document Header")
    var
        NFBDocumentLine: Record "NFB Document Line";
        Items: JsonArray;
        ItemNo: Integer;
    begin
        NFBDocumentLine.SetCurrentKey("Document No.", "Item Seq.");
        NFBDocumentLine.SetRange("Document No.", NFBDocumentHeader."No.");
        if not NFBDocumentLine.FindSet() then
            Error(NoLinesErr, NFBDocumentHeader."No.");
        repeat
            ItemNo += 1;
            Items.Add(BuildItem(NFBDocumentLine, ItemNo));
        until NFBDocumentLine.Next() = 0;
        Doc.Add('itens', Items);
    end;

    local procedure BuildItem(NFBDocumentLine: Record "NFB Document Line"; ItemNo: Integer) Item: JsonObject
    var
        Units: JsonObject;
        Quantities: JsonObject;
        UnitPrices: JsonObject;
        Taxes: JsonObject;
        GTIN: Text;
    begin
        GTIN := DefaultText(NFBDocumentLine.GTIN, 'SEM GTIN');
        Item.Add('numeroItem', ItemNo);
        Item.Add('codigo', NFBXMLBuilder.Clean(NFBDocumentLine."Product Code", 60));
        Item.Add('codigoBarras', GTIN);
        Item.Add('codigoBarrasTributavel', GTIN);
        Item.Add('descricao', NFBXMLBuilder.Clean(NFBDocumentLine.Description, 120));
        Item.Add('ncm', DefaultText(NFBDocumentLine.NCM, '00000000'));
        AddOptText(Item, 'cest', NFBDocumentLine.CEST);
        AddOptText(Item, 'exTipi', NFBDocumentLine."Ex TIPI");
        Item.Add('cfop', NFBDocumentLine.CFOP);

        Units.Add('comercial', NFBXMLBuilder.Clean(NFBDocumentLine."Commercial Unit", 6));
        Units.Add('tributavel', NFBXMLBuilder.Clean(DefaultText(NFBDocumentLine."Taxable Unit", NFBDocumentLine."Commercial Unit"), 6));
        Item.Add('unidade', Units);
        Quantities.Add('comercial', Round(NFBDocumentLine."Commercial Quantity", 0.0001));
        Quantities.Add('tributavel', Round(NFBDocumentLine."Taxable Quantity", 0.0001));
        Item.Add('quantidade', Quantities);
        UnitPrices.Add('comercial', Round(NFBDocumentLine."Commercial Unit Price", 0.0000000001));
        UnitPrices.Add('tributavel', Round(NFBDocumentLine."Taxable Unit Price", 0.0000000001));
        Item.Add('valorUnitario', UnitPrices);
        Item.Add('valor', Amount(NFBDocumentLine."Products Amount"));
        AddOptAmount(Item, 'valorFrete', NFBDocumentLine."Freight Amount");
        AddOptAmount(Item, 'valorSeguro', NFBDocumentLine."Insurance Amount");
        AddOptAmount(Item, 'valorDesconto', NFBDocumentLine."Discount Amount");
        AddOptAmount(Item, 'valorOutros', NFBDocumentLine."Other Expenses");
        Item.Add('compoeTotal', NFBDocumentLine."Include in Total");
        AddOptText(Item, 'informacoesComplementares', NFBXMLBuilder.Clean(NFBDocumentLine."Additional Info", 500));
        AddImport(Item, NFBDocumentLine);

        Taxes.Add('icms', BuildIcms(NFBDocumentLine));
        AddIpi(Taxes, NFBDocumentLine);
        Taxes.Add('pis', BuildPisCofins(NFBDocumentLine."PIS CST", NFBDocumentLine."PIS Base", NFBDocumentLine."PIS %", NFBDocumentLine."PIS Amount"));
        Taxes.Add('cofins', BuildPisCofins(NFBDocumentLine."COFINS CST", NFBDocumentLine."COFINS Base", NFBDocumentLine."COFINS %", NFBDocumentLine."COFINS Amount"));
        AddPartilha(Taxes, NFBDocumentLine);
        if NFBSetup."Include IBS/CBS Group" then
            AddIbsCbs(Taxes, NFBDocumentLine);
        Item.Add('tributos', Taxes);
    end;

    local procedure BuildIcms(NFBDocumentLine: Record "NFB Document Line") Icms: JsonObject
    var
        CST: Text;
    begin
        CST := DefaultText(CopyStr(NFBValidation.OnlyDigits(NFBDocumentLine."ICMS CST"), 1, 2), '00');
        Icms.Add('origem', Format(NFBDocumentLine.Origin.AsInteger()));
        Icms.Add('cst', CST);
        case CST of
            '00', '20':
                begin
                    AddOwnIcms(Icms, NFBDocumentLine, CST = '20');
                    AddFcp(Icms, NFBDocumentLine);
                end;
            '10', '70':
                begin
                    AddOwnIcms(Icms, NFBDocumentLine, CST = '70');
                    AddFcp(Icms, NFBDocumentLine);
                    AddIcmsSt(Icms, NFBDocumentLine);
                end;
            '30':
                AddIcmsSt(Icms, NFBDocumentLine);
            '51':
                if NFBDocumentLine."ICMS Base" <> 0 then
                    AddOwnIcms(Icms, NFBDocumentLine, NFBDocumentLine."ICMS Base Reduction %" <> 0);
            '90':
                begin
                    if NFBDocumentLine."ICMS Base" <> 0 then begin
                        AddOwnIcms(Icms, NFBDocumentLine, NFBDocumentLine."ICMS Base Reduction %" <> 0);
                        AddFcp(Icms, NFBDocumentLine);
                    end;
                    if NFBDocumentLine."ICMS ST Base" <> 0 then
                        AddIcmsSt(Icms, NFBDocumentLine);
                end;
        end;
    end;

    local procedure AddOwnIcms(var Icms: JsonObject; NFBDocumentLine: Record "NFB Document Line"; WithReduction: Boolean)
    var
        Base: JsonObject;
    begin
        Base.Add('modalidadeDeterminacao', 3);
        Base.Add('valor', Amount(NFBDocumentLine."ICMS Base"));
        if WithReduction then
            Base.Add('percentualReducao', Rate(NFBDocumentLine."ICMS Base Reduction %"));
        Icms.Add('baseCalculo', Base);
        Icms.Add('aliquota', Rate(NFBDocumentLine."ICMS %"));
        Icms.Add('valor', Amount(NFBDocumentLine."ICMS Amount"));
    end;

    local procedure AddFcp(var Icms: JsonObject; NFBDocumentLine: Record "NFB Document Line")
    var
        Fcp: JsonObject;
        Base: JsonObject;
    begin
        if NFBDocumentLine."FCP Amount" = 0 then
            exit;
        Base.Add('valor', Amount(DefaultDec(NFBDocumentLine."FCP Base", NFBDocumentLine."ICMS Base")));
        Fcp.Add('baseCalculo', Base);
        Fcp.Add('aliquota', Rate(NFBDocumentLine."FCP %"));
        Fcp.Add('valor', Amount(NFBDocumentLine."FCP Amount"));
        Icms.Add('fundoCombatePobreza', Fcp);
    end;

    local procedure AddIcmsSt(var Icms: JsonObject; NFBDocumentLine: Record "NFB Document Line")
    var
        St: JsonObject;
        Base: JsonObject;
        Mva: JsonObject;
        Fcp: JsonObject;
        FcpBase: JsonObject;
    begin
        if NFBDocumentLine."ICMS ST MVA %" <> 0 then
            Base.Add('modalidadeDeterminacao', 4)
        else
            Base.Add('modalidadeDeterminacao', 6);
        Base.Add('valor', Amount(NFBDocumentLine."ICMS ST Base"));
        if NFBDocumentLine."ICMS ST Base Reduction %" <> 0 then
            Base.Add('percentualReducao', Rate(NFBDocumentLine."ICMS ST Base Reduction %"));
        St.Add('baseCalculo', Base);
        if NFBDocumentLine."ICMS ST MVA %" <> 0 then begin
            Mva.Add('percentual', Rate(NFBDocumentLine."ICMS ST MVA %"));
            St.Add('margemValorAdicionado', Mva);
        end;
        St.Add('aliquota', Rate(NFBDocumentLine."ICMS ST %"));
        St.Add('valor', Amount(NFBDocumentLine."ICMS ST Amount"));
        if NFBDocumentLine."FCP ST Amount" <> 0 then begin
            FcpBase.Add('valor', Amount(DefaultDec(NFBDocumentLine."FCP ST Base", NFBDocumentLine."ICMS ST Base")));
            Fcp.Add('baseCalculo', FcpBase);
            Fcp.Add('aliquota', Rate(NFBDocumentLine."FCP ST %"));
            Fcp.Add('valor', Amount(NFBDocumentLine."FCP ST Amount"));
            St.Add('fundoCombatePobreza', Fcp);
        end;
        Icms.Add('substituicaoTributaria', St);
    end;

    local procedure AddIpi(var Taxes: JsonObject; NFBDocumentLine: Record "NFB Document Line")
    var
        Ipi: JsonObject;
        CST: Text;
    begin
        CST := NFBValidation.OnlyDigits(NFBDocumentLine."IPI CST");
        if CST = '' then
            exit;
        Ipi.Add('cst', CST);
        Ipi.Add('codigoEnquadramentoLegal', DefaultText(NFBDocumentLine."IPI Enq. Code", '999'));
        if CST in ['00', '49', '50', '99'] then begin
            Ipi.Add('baseCalculo', Amount(NFBDocumentLine."IPI Base"));
            Ipi.Add('aliquota', Rate(NFBDocumentLine."IPI %"));
            Ipi.Add('valor', Amount(NFBDocumentLine."IPI Amount"));
        end;
        Taxes.Add('ipi', Ipi);
    end;

    local procedure BuildPisCofins(CSTCode: Code[2]; BaseAmount: Decimal; TaxRate: Decimal; TaxAmount: Decimal) Tax: JsonObject
    var
        Base: JsonObject;
        CST: Text;
    begin
        CST := DefaultText(NFBValidation.OnlyDigits(CSTCode), '99');
        Tax.Add('cst', CST);
        // Non-taxed CSTs must not carry amounts, otherwise the XML generated by PlugNotas fails the schema.
        if CST in ['04', '05', '06', '07', '08', '09'] then
            exit;
        Base.Add('valor', Amount(BaseAmount));
        Tax.Add('baseCalculo', Base);
        Tax.Add('aliquota', Rate(TaxRate));
        Tax.Add('valor', Amount(TaxAmount));
    end;

    local procedure AddPartilha(var Taxes: JsonObject; NFBDocumentLine: Record "NFB Document Line")
    var
        Partilha: JsonObject;
        Destination: JsonObject;
        Origin: JsonObject;
    begin
        if (NFBDocumentLine."DIFAL Dest. Amount" = 0) and (NFBDocumentLine."FCP Dest. Amount" = 0) then
            exit;
        Destination.Add('baseCalculoIcms', Amount(NFBDocumentLine."DIFAL Base"));
        Destination.Add('baseCalculoFcp', Amount(NFBDocumentLine."DIFAL Base"));
        Destination.Add('percentualIcmsFcp', Rate(NFBDocumentLine."FCP Dest. %"));
        Destination.Add('aliquotaInterna', Rate(NFBDocumentLine."DIFAL Internal %"));
        Destination.Add('aliquotaInterestadual', Rate(NFBDocumentLine."DIFAL Interstate %"));
        Destination.Add('percentualProvisorioIcmsInterestadual', 100);
        Destination.Add('icmsRelativoFcp', Amount(NFBDocumentLine."FCP Dest. Amount"));
        Destination.Add('icmsInterestadual', Amount(NFBDocumentLine."DIFAL Dest. Amount"));
        Origin.Add('icmsInterestadual', 0);
        Partilha.Add('ufDestino', Destination);
        Partilha.Add('ufRemetente', Origin);
        Taxes.Add('partilha', Partilha);
    end;

    local procedure AddIbsCbs(var Taxes: JsonObject; NFBDocumentLine: Record "NFB Document Line")
    var
        IbsCbs: JsonObject;
    begin
        if NFBDocumentLine."IBS/CBS CST" = '' then
            exit;
        IbsCbs.Add('cst', NFBDocumentLine."IBS/CBS CST");
        IbsCbs.Add('classificacao', NFBDocumentLine.cClassTrib);
        if NFBDocumentLine."IBS/CBS Base" <> 0 then begin
            IbsCbs.Add('baseCalculo', Amount(NFBDocumentLine."IBS/CBS Base"));
            IbsCbs.Add('uf', BuildIbsCbsGroup(NFBDocumentLine."IBS UF %", NFBDocumentLine."IBS Reduction %", NFBDocumentLine."IBS UF Amount"));
            IbsCbs.Add('municipio', BuildIbsCbsGroup(NFBDocumentLine."IBS Mun. %", NFBDocumentLine."IBS Reduction %", NFBDocumentLine."IBS Mun. Amount"));
            IbsCbs.Add('valorIbs', Amount(NFBDocumentLine."IBS UF Amount" + NFBDocumentLine."IBS Mun. Amount"));
            IbsCbs.Add('cbs', BuildIbsCbsGroup(NFBDocumentLine."CBS %", NFBDocumentLine."CBS Reduction %", NFBDocumentLine."CBS Amount"));
        end;
        Taxes.Add('ibscbs', IbsCbs);
    end;

    local procedure BuildIbsCbsGroup(TaxRate: Decimal; ReductionPct: Decimal; TaxAmount: Decimal) Grp: JsonObject
    var
        Reduction: JsonObject;
    begin
        Grp.Add('aliquota', Rate(TaxRate));
        Grp.Add('valor', Amount(TaxAmount));
        if ReductionPct = 0 then
            exit;
        Reduction.Add('aliquota', Rate(ReductionPct));
        Reduction.Add('aliquotaEfetiva', Rate(TaxRate * (1 - ReductionPct / 100)));
        Grp.Add('reducao', Reduction);
    end;

    local procedure AddImport(var Item: JsonObject; NFBDocumentLine: Record "NFB Document Line")
    var
        NFBImportDeclaration: Record "NFB Import Declaration";
        Import: JsonObject;
        Clearance: JsonObject;
        Addition: JsonObject;
        ImportTax: JsonObject;
        Imports: JsonArray;
        Intermediation: Integer;
    begin
        // Structure taken from the PlugNotas SDK models (importacao); check it in the sandbox before issuing imports.
        if not NFBImportDeclaration.Get(Database::"NFB Document Line", 0, NFBDocumentLine."Document No.", NFBDocumentLine."Line No.") then
            exit;
        Intermediation := NFBImportDeclaration."Intermediation Type";
        if Intermediation = 0 then
            Intermediation := 1;
        Import.Add('numero', NFBImportDeclaration."Declaration No.");
        Import.Add('dataEmissao', NFBXMLBuilder.FormatDate(NFBImportDeclaration."Declaration Date"));
        Import.Add('viaTransporte', Format(NFBImportDeclaration."Transport Mode"));
        if NFBImportDeclaration."Transport Mode" = 1 then
            Import.Add('valorAfrmm', NFBXMLBuilder.FormatDec(NFBImportDeclaration."AFRMM Amount", 2, 2));
        Import.Add('formaImportacao', Format(Intermediation));
        Import.Add('codigoExportador', NFBXMLBuilder.Clean(NFBImportDeclaration."Exporter Code", 60));
        Clearance.Add('local', NFBXMLBuilder.Clean(NFBImportDeclaration."Customs Place", 60));
        Clearance.Add('endereco', NFBImportDeclaration."Customs UF");
        Clearance.Add('data', NFBXMLBuilder.FormatDate(NFBImportDeclaration."Customs Date"));
        Import.Add('desembaraco', Clearance);
        Addition.Add('numero', Format(MaxInt(NFBImportDeclaration."Addition No.", 1)));
        Addition.Add('numeroSequencia', Format(MaxInt(NFBImportDeclaration."Addition Seq.", 1)));
        Addition.Add('codigoFabricante', NFBXMLBuilder.Clean(DefaultText(NFBImportDeclaration."Manufacturer Code", NFBImportDeclaration."Exporter Code"), 60));
        Import.Add('adicoes', Addition);
        if CopyStr(NFBDocumentLine.CFOP, 1, 1) = '3' then begin
            ImportTax.Add('baseCalculo', Amount(NFBDocumentLine."II Base"));
            ImportTax.Add('valorDespesasAduaneiras', Amount(NFBDocumentLine."II Customs Expenses"));
            ImportTax.Add('valor', Amount(NFBDocumentLine."II Amount"));
            ImportTax.Add('valorOperacoesFinanceiras', Amount(NFBDocumentLine."IOF Amount"));
            Import.Add('impostoImportacao', ImportTax);
        end;
        Imports.Add(Import);
        Item.Add('importacao', Imports);
    end;

    local procedure AddTotal(var Doc: JsonObject; NFBDocumentHeader: Record "NFB Document Header")
    var
        Total: JsonObject;
    begin
        Total.Add('baseCalculoIcms', Amount(NFBDocumentHeader."ICMS Base"));
        Total.Add('valorIcms', Amount(NFBDocumentHeader."ICMS Amount"));
        Total.Add('valorIcmsDesonerado', 0);
        Total.Add('valorFcp', Amount(NFBDocumentHeader."FCP Amount"));
        Total.Add('baseCalculoIcmsSt', Amount(NFBDocumentHeader."ICMS ST Base"));
        Total.Add('valorIcmsSt', Amount(NFBDocumentHeader."ICMS ST Amount"));
        Total.Add('valorFcpSt', Amount(NFBDocumentHeader."FCP ST Amount"));
        Total.Add('valorFcpStRetido', 0);
        Total.Add('valorProdutosServicos', Amount(NFBDocumentHeader."Products Amount"));
        Total.Add('valorFrete', Amount(NFBDocumentHeader."Freight Amount"));
        Total.Add('valorSeguro', Amount(NFBDocumentHeader."Insurance Amount"));
        Total.Add('valorDesconto', Amount(NFBDocumentHeader."Discount Amount"));
        Total.Add('valorIi', Amount(NFBDocumentHeader."II Amount"));
        Total.Add('valorIpi', Amount(NFBDocumentHeader."IPI Amount"));
        Total.Add('valorIpiDevolvido', 0);
        Total.Add('valorPis', Amount(NFBDocumentHeader."PIS Amount"));
        Total.Add('valorCofins', Amount(NFBDocumentHeader."COFINS Amount"));
        Total.Add('valorOutros', Amount(NFBDocumentHeader."Other Expenses"));
        Total.Add('valorNfe', Amount(NFBDocumentHeader."Invoice Amount"));
        if NFBSetup."Include IBS/CBS Group" then begin
            Total.Add('baseCalculoIbsCbs', Amount(NFBDocumentHeader."IBS/CBS Base"));
            Total.Add('valorIbsUF', Amount(NFBDocumentHeader."IBS UF Amount"));
            Total.Add('valorIbsMunicipio', Amount(NFBDocumentHeader."IBS Mun. Amount"));
            Total.Add('valorIbs', Amount(NFBDocumentHeader."IBS UF Amount" + NFBDocumentHeader."IBS Mun. Amount"));
            Total.Add('valorCbs', Amount(NFBDocumentHeader."CBS Amount"));
        end;
        Doc.Add('total', Total);
    end;

    local procedure AddTransport(var Doc: JsonObject; NFBDocumentHeader: Record "NFB Document Header")
    var
        NFBDocumentTransport: Record "NFB Document Transport";
        Transport: JsonObject;
        Carrier: JsonObject;
        Vehicle: JsonObject;
        Volume: JsonObject;
        Volumes: JsonArray;
    begin
        if not NFBDocumentTransport.Get(NFBDocumentHeader."No.") then begin
            Transport.Add('modalidadeFrete', '9');
            Doc.Add('transporte', Transport);
            exit;
        end;
        Transport.Add('modalidadeFrete', Format(NFBDocumentTransport."Freight Mode".AsInteger()));
        if (NFBDocumentTransport."Carrier Name" <> '') or (NFBDocumentTransport."Carrier CPF/CNPJ" <> '') then begin
            AddOptText(Carrier, 'cpfCnpj', NFBValidation.OnlyDigits(NFBDocumentTransport."Carrier CPF/CNPJ"));
            AddOptText(Carrier, 'razaoSocial', NFBXMLBuilder.Clean(NFBDocumentTransport."Carrier Name", 60));
            AddOptText(Carrier, 'inscricaoEstadual', NFBValidation.OnlyDigits(NFBDocumentTransport."Carrier IE"));
            AddOptText(Carrier, 'endereco', NFBXMLBuilder.Clean(NFBDocumentTransport."Carrier Address", 60));
            AddOptText(Carrier, 'municipio', NFBXMLBuilder.Clean(NFBDocumentTransport."Carrier City", 60));
            AddOptText(Carrier, 'uf', NFBDocumentTransport."Carrier UF");
            Transport.Add('transportadora', Carrier);
        end;
        if (NFBDocumentTransport."Vehicle Plate" <> '') and (NFBDocumentHeader."Destination Id" = NFBDocumentHeader."Destination Id"::Internal) then begin
            Vehicle.Add('placa', NFBDocumentTransport."Vehicle Plate");
            AddOptText(Vehicle, 'uf', NFBDocumentTransport."Vehicle UF");
            Transport.Add('veiculo', Vehicle);
        end;
        if (NFBDocumentTransport."Volume Quantity" <> 0) or (NFBDocumentTransport."Gross Weight" <> 0) then begin
            if NFBDocumentTransport."Volume Quantity" <> 0 then
                Volume.Add('quantidade', NFBDocumentTransport."Volume Quantity");
            AddOptText(Volume, 'especie', NFBXMLBuilder.Clean(NFBDocumentTransport."Volume Kind", 60));
            AddOptText(Volume, 'marca', NFBXMLBuilder.Clean(NFBDocumentTransport.Brand, 60));
            if NFBDocumentTransport."Net Weight" <> 0 then
                Volume.Add('pesoLiquido', Round(NFBDocumentTransport."Net Weight", 0.001));
            if NFBDocumentTransport."Gross Weight" <> 0 then
                Volume.Add('pesoBruto', Round(NFBDocumentTransport."Gross Weight", 0.001));
            Volumes.Add(Volume);
            Transport.Add('volumes', Volumes);
        end;
        Doc.Add('transporte', Transport);
    end;

    local procedure AddBilling(var Doc: JsonObject; NFBDocumentHeader: Record "NFB Document Header")
    var
        NFBDocumentInstallment: Record "NFB Document Installment";
        Billing: JsonObject;
        Invoice: JsonObject;
        Installment: JsonObject;
        Installments: JsonArray;
        Total: Decimal;
    begin
        NFBDocumentInstallment.SetRange("Document No.", NFBDocumentHeader."No.");
        if NFBDocumentInstallment.IsEmpty() then
            exit;
        NFBDocumentInstallment.CalcSums(Amount);
        Total := NFBDocumentInstallment.Amount;
        Invoice.Add('numero', Format(NFBDocumentHeader."NF No."));
        Invoice.Add('valorTotal', Amount(Total));
        Invoice.Add('valorDesconto', 0);
        Invoice.Add('valorLiquido', Amount(Total));
        Billing.Add('fatura', Invoice);
        NFBDocumentInstallment.FindSet();
        repeat
            Clear(Installment);
            Installment.Add('numero', NFBDocumentInstallment."Installment No.");
            Installment.Add('dataVencimento', NFBXMLBuilder.FormatDate(NFBDocumentInstallment."Due Date"));
            Installment.Add('valor', Amount(NFBDocumentInstallment.Amount));
            Installments.Add(Installment);
        until NFBDocumentInstallment.Next() = 0;
        Billing.Add('parcelas', Installments);
        Doc.Add('cobranca', Billing);
    end;

    local procedure AddPayments(var Doc: JsonObject; NFBDocumentHeader: Record "NFB Document Header")
    var
        NFBDocumentPayment: Record "NFB Document Payment";
        Payments: JsonArray;
        Payment: JsonObject;
        Card: JsonObject;
        CardIntegration: Integer;
    begin
        NFBDocumentPayment.SetRange("Document No.", NFBDocumentHeader."No.");
        if not NFBDocumentPayment.FindSet() then begin
            Payment.Add('meio', '90');
            Payment.Add('valor', 0);
            Payments.Add(Payment);
            Doc.Add('pagamentos', Payments);
            exit;
        end;
        repeat
            Clear(Payment);
            Clear(Card);
            Payment.Add('aVista', NFBDocumentPayment."Payment Indicator" = NFBDocumentPayment."Payment Indicator"::Cash);
            Payment.Add('meio', DefaultText(NFBDocumentPayment."Payment Type", '99'));
            if NFBDocumentPayment."Payment Type" = '99' then
                Payment.Add('descricaoMeio', DefaultText(NFBXMLBuilder.Clean(NFBDocumentPayment.Description, 60), 'Outros'));
            Payment.Add('valor', Amount(NFBDocumentPayment.Amount));
            if NFBDocumentPayment.Change <> 0 then
                Payment.Add('troco', Amount(NFBDocumentPayment.Change));
            if (NFBDocumentPayment."Payment Type" in ['03', '04', '17']) and (NFBDocumentPayment."Card Integration" <> NFBDocumentPayment."Card Integration"::" ") then begin
                CardIntegration := NFBDocumentPayment."Card Integration";
                Card.Add('tipoIntegracao', CardIntegration);
                AddOptText(Card, 'cnpjCredenciadora', NFBValidation.OnlyDigits(NFBDocumentPayment."Card Acquirer CNPJ"));
                AddOptText(Card, 'bandeiraOperadora', NFBDocumentPayment."Card Brand");
                AddOptText(Card, 'numeroAutorizacao', NFBDocumentPayment."Card Authorization");
                Payment.Add('cartao', Card);
            end;
            Payments.Add(Payment);
        until NFBDocumentPayment.Next() = 0;
        Doc.Add('pagamentos', Payments);
    end;

    local procedure AddExport(var Doc: JsonObject; NFBDocumentHeader: Record "NFB Document Header")
    var
        Export: JsonObject;
    begin
        if (NFBDocumentHeader."Destination Id" <> NFBDocumentHeader."Destination Id"::Exterior) or (NFBDocumentHeader."Export Shipping UF" = '') then
            exit;
        Export.Add('estadoEmbarque', NFBDocumentHeader."Export Shipping UF");
        Export.Add('descricaoLocalEmbarque', NFBXMLBuilder.Clean(NFBDocumentHeader."Export Shipping Place", 60));
        Doc.Add('exportacao', Export);
    end;

    local procedure AddTechResponsible(var Doc: JsonObject)
    var
        Responsible: JsonObject;
    begin
        if NFBSetup."Resp. Tech. CNPJ" = '' then
            exit;
        Responsible.Add('cpfCnpj', NFBValidation.OnlyDigits(NFBSetup."Resp. Tech. CNPJ"));
        Responsible.Add('nome', NFBXMLBuilder.Clean(NFBSetup."Resp. Tech. Contact", 60));
        Responsible.Add('email', NFBXMLBuilder.Clean(NFBSetup."Resp. Tech. E-Mail", 60));
        AddPhone(Responsible, NFBSetup."Resp. Tech. Phone");
        Doc.Add('responsavelTecnico', Responsible);
    end;

    local procedure AddPhone(var Parent: JsonObject; Phone: Text)
    var
        Telephone: JsonObject;
        Digits: Text;
    begin
        Digits := NFBValidation.OnlyDigits(Phone);
        if StrLen(Digits) < 10 then
            exit;
        Telephone.Add('ddd', CopyStr(Digits, 1, 2));
        Telephone.Add('numero', CopyStr(Digits, 3));
        Parent.Add('telefone', Telephone);
    end;

    local procedure AddOptText(var Parent: JsonObject; Name: Text; Value: Text)
    begin
        if Value <> '' then
            Parent.Add(Name, Value);
    end;

    local procedure AddOptAmount(var Parent: JsonObject; Name: Text; Value: Decimal)
    begin
        if Value <> 0 then
            Parent.Add(Name, Amount(Value));
    end;

    local procedure Amount(Value: Decimal): Decimal
    begin
        exit(Round(Value, 0.01));
    end;

    local procedure Rate(Value: Decimal): Decimal
    begin
        exit(Round(Value, 0.0001));
    end;

    local procedure DefaultText(Value: Text; Default: Text): Text
    begin
        if Value = '' then
            exit(Default);
        exit(Value);
    end;

    local procedure DefaultDec(Value: Decimal; Default: Decimal): Decimal
    begin
        if Value = 0 then
            exit(Default);
        exit(Value);
    end;

    local procedure MaxInt(Value: Integer; Minimum: Integer): Integer
    begin
        if Value < Minimum then
            exit(Minimum);
        exit(Value);
    end;
}
