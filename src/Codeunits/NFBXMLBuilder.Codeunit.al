codeunit 50113 "NFB XML Builder"
{
    // Builds the NF-e XML, layout 4.00 (MOC 7.0), with the IBS/CBS groups of NT 2025.002.
    // The XML is unsigned: the Signature element is added by the signer (phase 4) or by the provider.

    var
        NFBSetup: Record "NFB Setup";
        NFBAccessKeyMgt: Codeunit "NFB Access Key Mgt";
        NFBValidation: Codeunit "NFB Validation";
        HomologationNameTxt: Label 'NF-E EMITIDA EM AMBIENTE DE HOMOLOGACAO - SEM VALOR FISCAL', Locked = true;
        NoAccessKeyErr: Label 'NF-e %1 has no access key. Validate it before generating the XML.', Comment = '%1 = document no.';
        SimplesNotSupportedErr: Label 'The issuer tax regime is Simples Nacional (CSOSN), which this version does not generate.';
        NoLinesErr: Label 'NF-e %1 has no lines.', Comment = '%1 = document no.';

    procedure NamespaceUri(): Text
    begin
        exit('http://www.portalfiscal.inf.br/nfe');
    end;

    /// <summary>
    /// Builds the NFe element (unsigned) for the document and writes it, UTF-8 encoded, to TempBlob.
    /// </summary>
    procedure BuildXml(var NFBDocumentHeader: Record "NFB Document Header"; var TempBlob: Codeunit "Temp Blob")
    var
        XmlDoc: XmlDocument;
        OutStr: OutStream;
    begin
        BuildXmlDocument(NFBDocumentHeader, XmlDoc);
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        XmlDoc.WriteTo(OutStr);
    end;

    procedure BuildXmlDocument(var NFBDocumentHeader: Record "NFB Document Header"; var XmlDoc: XmlDocument)
    var
        NFeElement: XmlElement;
        InfNFe: XmlElement;
    begin
        NFBSetup.Get();
        if NFBDocumentHeader."Access Key" = '' then
            Error(NoAccessKeyErr, NFBDocumentHeader."No.");
        if NFBDocumentHeader."Issuer CRT" in [NFBDocumentHeader."Issuer CRT"::"Simples Nacional", NFBDocumentHeader."Issuer CRT"::MEI] then
            Error(SimplesNotSupportedErr);

        XmlDoc := XmlDocument.Create();
        XmlDoc.SetDeclaration(XmlDeclaration.Create('1.0', 'UTF-8', ''));
        NFeElement := XmlElement.Create('NFe', NamespaceUri());
        XmlDoc.Add(NFeElement);

        InfNFe := XmlElement.Create('infNFe', NamespaceUri());
        InfNFe.SetAttribute('versao', '4.00');
        InfNFe.SetAttribute('Id', 'NFe' + NFBDocumentHeader."Access Key");
        NFeElement.Add(InfNFe);

        AddIde(InfNFe, NFBDocumentHeader);
        AddEmit(InfNFe, NFBDocumentHeader);
        AddDest(InfNFe, NFBDocumentHeader);
        AddDetails(InfNFe, NFBDocumentHeader);
        AddTotal(InfNFe, NFBDocumentHeader);
        AddTransp(InfNFe, NFBDocumentHeader);
        AddCobr(InfNFe, NFBDocumentHeader);
        AddPag(InfNFe, NFBDocumentHeader);
        AddInfAdic(InfNFe, NFBDocumentHeader);
        AddExporta(InfNFe, NFBDocumentHeader);
        AddInfRespTec(InfNFe);
    end;

    local procedure AddIde(var InfNFe: XmlElement; NFBDocumentHeader: Record "NFB Document Header")
    var
        NFBDocumentReference: Record "NFB Document Reference";
        Ide: XmlElement;
        NFref: XmlElement;
        EmissionType: Integer;
    begin
        EmissionType := NFBDocumentHeader."Emission Type";
        if EmissionType = 0 then
            EmissionType := 1;
        Ide := AddGroup(InfNFe, 'ide');
        AddText(Ide, 'cUF', NFBDocumentHeader."Issuer UF Code");
        AddText(Ide, 'cNF', NFBDocumentHeader."Numeric Code");
        AddText(Ide, 'natOp', Clean(NFBDocumentHeader."Nature of Operation", 60));
        AddText(Ide, 'mod', DefaultText(NFBDocumentHeader.Model, '55'));
        AddText(Ide, 'serie', Format(NFBDocumentHeader.Series));
        AddText(Ide, 'nNF', Format(NFBDocumentHeader."NF No."));
        AddText(Ide, 'dhEmi', FormatDateTimeTZ(NFBDocumentHeader."Issue DateTime"));
        if NFBDocumentHeader."Exit DateTime" <> 0DT then
            AddText(Ide, 'dhSaiEnt', FormatDateTimeTZ(NFBDocumentHeader."Exit DateTime"));
        AddText(Ide, 'tpNF', Format(NFBDocumentHeader.Direction.AsInteger()));
        AddText(Ide, 'idDest', Format(NFBDocumentHeader."Destination Id".AsInteger()));
        AddText(Ide, 'cMunFG', NFBDocumentHeader."Taxable Event Municipality");
        AddText(Ide, 'tpImp', '1');
        AddText(Ide, 'tpEmis', Format(EmissionType));
        AddText(Ide, 'cDV', Format(NFBDocumentHeader."Check Digit"));
        AddText(Ide, 'tpAmb', Format(NFBDocumentHeader.Environment.AsInteger()));
        AddText(Ide, 'finNFe', Format(NFBDocumentHeader.Purpose.AsInteger()));
        AddText(Ide, 'indFinal', BoolText(NFBDocumentHeader."Final Consumer"));
        AddText(Ide, 'indPres', Format(NFBDocumentHeader."Presence Indicator".AsInteger()));
        if NFBDocumentHeader."Presence Indicator".AsInteger() in [2, 3, 4, 9] then
            AddText(Ide, 'indIntermed', '0');
        AddText(Ide, 'procEmi', '0');
        AddText(Ide, 'verProc', DefaultText(NFBSetup."Software Version", 'NFB 1.0'));
        if EmissionType <> 1 then begin
            AddText(Ide, 'dhCont', FormatDateTimeTZ(NFBDocumentHeader."Issue DateTime"));
            AddText(Ide, 'xJust', 'Falha de comunicacao com a SEFAZ autorizadora');
        end;

        NFBDocumentReference.SetRange("Document No.", NFBDocumentHeader."No.");
        if NFBDocumentReference.FindSet() then
            repeat
                if NFBDocumentReference."Referenced Access Key" <> '' then begin
                    NFref := AddGroup(Ide, 'NFref');
                    AddText(NFref, 'refNFe', NFBDocumentReference."Referenced Access Key");
                end;
            until NFBDocumentReference.Next() = 0;
    end;

    local procedure AddEmit(var InfNFe: XmlElement; NFBDocumentHeader: Record "NFB Document Header")
    var
        CompanyInformation: Record "Company Information";
        Location: Record Location;
        NFBMunicipality: Record "NFB Municipality";
        Emit: XmlElement;
        Ender: XmlElement;
        Address: Text;
        AddressNo: Text;
        Address2: Text;
        District: Text;
        MunicipalityCode: Code[7];
        City: Text;
        UF: Text;
        PostCode: Text;
        Phone: Text;
    begin
        CompanyInformation.Get();
        Address := CompanyInformation.Address;
        AddressNo := CompanyInformation."NFB Address No.";
        Address2 := CompanyInformation."Address 2";
        District := CompanyInformation."NFB District";
        MunicipalityCode := CompanyInformation."NFB Municipality Code";
        City := CompanyInformation.City;
        UF := CompanyInformation."NFB UF";
        PostCode := CompanyInformation."Post Code";
        Phone := CompanyInformation."Phone No.";
        if (NFBDocumentHeader."Issuer Location Code" <> '') and Location.Get(NFBDocumentHeader."Issuer Location Code") then begin
            Address := Location.Address;
            AddressNo := Location."NFB Address No.";
            Address2 := Location."Address 2";
            District := Location."NFB District";
            MunicipalityCode := Location."NFB Municipality Code";
            City := Location.City;
            UF := Location."NFB UF";
            PostCode := Location."Post Code";
            if Location."Phone No." <> '' then
                Phone := Location."Phone No.";
        end;
        if NFBMunicipality.Get(MunicipalityCode) then
            City := NFBMunicipality.Name;

        Emit := AddGroup(InfNFe, 'emit');
        AddText(Emit, 'CNPJ', NFBValidation.OnlyDigits(NFBDocumentHeader."Issuer CNPJ"));
        AddText(Emit, 'xNome', Clean(NFBDocumentHeader."Issuer Name", 60));
        AddOptText(Emit, 'xFant', Clean(CompanyInformation."Name 2", 60));
        Ender := AddGroup(Emit, 'enderEmit');
        AddText(Ender, 'xLgr', Clean(Address, 60));
        AddText(Ender, 'nro', DefaultText(Clean(AddressNo, 60), 'S/N'));
        AddOptText(Ender, 'xCpl', Clean(Address2, 60));
        AddText(Ender, 'xBairro', Clean(District, 60));
        AddText(Ender, 'cMun', MunicipalityCode);
        AddText(Ender, 'xMun', Clean(City, 60));
        AddText(Ender, 'UF', UF);
        AddText(Ender, 'CEP', NFBValidation.OnlyDigits(PostCode));
        AddText(Ender, 'cPais', '1058');
        AddText(Ender, 'xPais', 'BRASIL');
        AddOptText(Ender, 'fone', NFBValidation.OnlyDigits(Phone));
        AddText(Emit, 'IE', NFBValidation.OnlyDigits(NFBDocumentHeader."Issuer IE"));
        AddOptText(Emit, 'IEST', NFBValidation.OnlyDigits(CompanyInformation."NFB ST IE"));
        if CompanyInformation."NFB IM" <> '' then begin
            AddText(Emit, 'IM', CompanyInformation."NFB IM");
            AddOptText(Emit, 'CNAE', NFBValidation.OnlyDigits(CompanyInformation."NFB CNAE"));
        end;
        AddText(Emit, 'CRT', Format(NFBDocumentHeader."Issuer CRT".AsInteger()));
    end;

    local procedure AddDest(var InfNFe: XmlElement; NFBDocumentHeader: Record "NFB Document Header")
    var
        Dest: XmlElement;
        Ender: XmlElement;
        RecipientName: Text;
        IsForeign: Boolean;
    begin
        IsForeign := NFBDocumentHeader."Recipient Type" = NFBDocumentHeader."Recipient Type"::Foreign;
        Dest := AddGroup(InfNFe, 'dest');
        case NFBDocumentHeader."Recipient Type" of
            NFBDocumentHeader."Recipient Type"::"Legal Entity":
                AddText(Dest, 'CNPJ', NFBValidation.OnlyDigits(NFBDocumentHeader."Recipient CPF/CNPJ"));
            NFBDocumentHeader."Recipient Type"::"Natural Person":
                AddText(Dest, 'CPF', NFBValidation.OnlyDigits(NFBDocumentHeader."Recipient CPF/CNPJ"));
            NFBDocumentHeader."Recipient Type"::Foreign:
                AddText(Dest, 'idEstrangeiro', NFBDocumentHeader."Recipient Foreign Id");
        end;
        RecipientName := Clean(NFBDocumentHeader."Recipient Name", 60);
        if NFBDocumentHeader.Environment = NFBDocumentHeader.Environment::Homologation then
            RecipientName := HomologationNameTxt;
        AddText(Dest, 'xNome', RecipientName);

        Ender := AddGroup(Dest, 'enderDest');
        AddText(Ender, 'xLgr', Clean(NFBDocumentHeader."Recipient Address", 60));
        AddText(Ender, 'nro', DefaultText(Clean(NFBDocumentHeader."Recipient Address No.", 60), 'S/N'));
        AddOptText(Ender, 'xCpl', Clean(NFBDocumentHeader."Recipient Address 2", 60));
        AddText(Ender, 'xBairro', DefaultText(Clean(NFBDocumentHeader."Recipient District", 60), IIf(IsForeign, 'EXTERIOR', '')));
        AddText(Ender, 'cMun', NFBDocumentHeader."Recipient Municipality Code");
        AddText(Ender, 'xMun', Clean(NFBDocumentHeader."Recipient City", 60));
        AddText(Ender, 'UF', NFBDocumentHeader."Recipient UF");
        if not IsForeign then
            AddOptText(Ender, 'CEP', NFBValidation.OnlyDigits(NFBDocumentHeader."Recipient Post Code"));
        AddText(Ender, 'cPais', DefaultText(NFBDocumentHeader."Recipient BACEN Code", '1058'));
        AddText(Ender, 'xPais', DefaultText(Clean(NFBDocumentHeader."Recipient Country", 60), 'BRASIL'));
        AddOptText(Ender, 'fone', NFBValidation.OnlyDigits(NFBDocumentHeader."Recipient Phone"));

        AddText(Dest, 'indIEDest', Format(NFBDocumentHeader."Recipient IE Indicator".AsInteger()));
        if NFBDocumentHeader."Recipient IE Indicator" = NFBDocumentHeader."Recipient IE Indicator"::Contributor then
            AddText(Dest, 'IE', NFBValidation.OnlyDigits(NFBDocumentHeader."Recipient IE"));
        AddOptText(Dest, 'ISUF', NFBDocumentHeader."Recipient SUFRAMA");
        AddOptText(Dest, 'email', Clean(NFBDocumentHeader."Recipient E-Mail", 60));
    end;

    local procedure AddDetails(var InfNFe: XmlElement; NFBDocumentHeader: Record "NFB Document Header")
    var
        NFBDocumentLine: Record "NFB Document Line";
        Det: XmlElement;
        ItemNo: Integer;
    begin
        NFBDocumentLine.SetRange("Document No.", NFBDocumentHeader."No.");
        NFBDocumentLine.SetCurrentKey("Document No.", "Item Seq.");
        if not NFBDocumentLine.FindSet() then
            Error(NoLinesErr, NFBDocumentHeader."No.");
        repeat
            ItemNo += 1;
            Det := AddGroup(InfNFe, 'det');
            Det.SetAttribute('nItem', Format(ItemNo));
            AddProd(Det, NFBDocumentLine);
            AddImposto(Det, NFBDocumentHeader, NFBDocumentLine);
            AddOptText(Det, 'infAdProd', Clean(NFBDocumentLine."Additional Info", 500));
        until NFBDocumentLine.Next() = 0;
    end;

    local procedure AddProd(var Det: XmlElement; NFBDocumentLine: Record "NFB Document Line")
    var
        Prod: XmlElement;
        GTIN: Text;
    begin
        GTIN := DefaultText(NFBDocumentLine.GTIN, 'SEM GTIN');
        Prod := AddGroup(Det, 'prod');
        AddText(Prod, 'cProd', Clean(NFBDocumentLine."Product Code", 60));
        AddText(Prod, 'cEAN', GTIN);
        AddText(Prod, 'xProd', Clean(NFBDocumentLine.Description, 120));
        AddText(Prod, 'NCM', DefaultText(NFBDocumentLine.NCM, '00000000'));
        AddOptText(Prod, 'CEST', NFBDocumentLine.CEST);
        AddOptText(Prod, 'EXTIPI', NFBDocumentLine."Ex TIPI");
        AddText(Prod, 'CFOP', NFBDocumentLine.CFOP);
        AddText(Prod, 'uCom', Clean(NFBDocumentLine."Commercial Unit", 6));
        AddText(Prod, 'qCom', FormatDec(NFBDocumentLine."Commercial Quantity", 4, 4));
        AddText(Prod, 'vUnCom', FormatDec(NFBDocumentLine."Commercial Unit Price", 2, 10));
        AddText(Prod, 'vProd', FormatDec(NFBDocumentLine."Products Amount", 2, 2));
        AddText(Prod, 'cEANTrib', GTIN);
        AddText(Prod, 'uTrib', Clean(DefaultText(NFBDocumentLine."Taxable Unit", NFBDocumentLine."Commercial Unit"), 6));
        AddText(Prod, 'qTrib', FormatDec(NFBDocumentLine."Taxable Quantity", 4, 4));
        AddText(Prod, 'vUnTrib', FormatDec(NFBDocumentLine."Taxable Unit Price", 2, 10));
        AddOptAmount(Prod, 'vFrete', NFBDocumentLine."Freight Amount");
        AddOptAmount(Prod, 'vSeg', NFBDocumentLine."Insurance Amount");
        AddOptAmount(Prod, 'vDesc', NFBDocumentLine."Discount Amount");
        AddOptAmount(Prod, 'vOutro', NFBDocumentLine."Other Expenses");
        AddText(Prod, 'indTot', BoolText(NFBDocumentLine."Include in Total"));
        AddDI(Prod, NFBDocumentLine);
    end;

    local procedure AddDI(var Prod: XmlElement; NFBDocumentLine: Record "NFB Document Line")
    var
        NFBImportDeclaration: Record "NFB Import Declaration";
        DI: XmlElement;
        Adi: XmlElement;
        Intermediation: Integer;
    begin
        if not NFBImportDeclaration.Get(Database::"NFB Document Line", 0, NFBDocumentLine."Document No.", NFBDocumentLine."Line No.") then
            exit;
        Intermediation := NFBImportDeclaration."Intermediation Type";
        if Intermediation = 0 then
            Intermediation := 1;
        DI := AddGroup(Prod, 'DI');
        AddText(DI, 'nDI', NFBImportDeclaration."Declaration No.");
        AddText(DI, 'dDI', FormatDate(NFBImportDeclaration."Declaration Date"));
        AddText(DI, 'xLocDesemb', Clean(NFBImportDeclaration."Customs Place", 60));
        AddText(DI, 'UFDesemb', NFBImportDeclaration."Customs UF");
        AddText(DI, 'dDesemb', FormatDate(NFBImportDeclaration."Customs Date"));
        AddText(DI, 'tpViaTransp', Format(NFBImportDeclaration."Transport Mode"));
        if NFBImportDeclaration."Transport Mode" = 1 then
            AddText(DI, 'vAFRMM', FormatDec(NFBImportDeclaration."AFRMM Amount", 2, 2));
        AddText(DI, 'tpIntermedio', Format(Intermediation));
        AddText(DI, 'cExportador', Clean(NFBImportDeclaration."Exporter Code", 60));
        Adi := AddGroup(DI, 'adi');
        AddText(Adi, 'nAdicao', Format(MaxInt(NFBImportDeclaration."Addition No.", 1)));
        AddText(Adi, 'nSeqAdic', Format(MaxInt(NFBImportDeclaration."Addition Seq.", 1)));
        AddText(Adi, 'cFabricante', Clean(DefaultText(NFBImportDeclaration."Manufacturer Code", NFBImportDeclaration."Exporter Code"), 60));
    end;

    local procedure AddImposto(var Det: XmlElement; NFBDocumentHeader: Record "NFB Document Header"; NFBDocumentLine: Record "NFB Document Line")
    var
        Imposto: XmlElement;
    begin
        Imposto := AddGroup(Det, 'imposto');
        AddICMS(Imposto, NFBDocumentLine);
        AddIPI(Imposto, NFBDocumentLine);
        AddII(Imposto, NFBDocumentHeader, NFBDocumentLine);
        AddPisCofins(Imposto, 'PIS', NFBDocumentLine."PIS CST", NFBDocumentLine."PIS Base", NFBDocumentLine."PIS %", NFBDocumentLine."PIS Amount");
        AddPisCofins(Imposto, 'COFINS', NFBDocumentLine."COFINS CST", NFBDocumentLine."COFINS Base", NFBDocumentLine."COFINS %", NFBDocumentLine."COFINS Amount");
        AddICMSUFDest(Imposto, NFBDocumentLine);
        if NFBSetup."Include IBS/CBS Group" then
            AddIBSCBS(Imposto, NFBDocumentLine);
    end;

    local procedure AddICMS(var Imposto: XmlElement; NFBDocumentLine: Record "NFB Document Line")
    var
        ICMS: XmlElement;
        Grp: XmlElement;
        CST: Text;
        GroupCST: Text;
    begin
        CST := DefaultText(CopyStr(NFBValidation.OnlyDigits(NFBDocumentLine."ICMS CST"), 1, 2), '00');
        case CST of
            '41', '50':
                GroupCST := '40';
            else
                GroupCST := CST;
        end;
        ICMS := AddGroup(Imposto, 'ICMS');
        Grp := AddGroup(ICMS, 'ICMS' + GroupCST);
        AddText(Grp, 'orig', Format(NFBDocumentLine.Origin.AsInteger()));
        AddText(Grp, 'CST', CST);
        case CST of
            '00':
                begin
                    AddOwnIcms(Grp, NFBDocumentLine, false);
                    if NFBDocumentLine."FCP Amount" <> 0 then begin
                        AddText(Grp, 'pFCP', FormatDec(NFBDocumentLine."FCP %", 2, 4));
                        AddText(Grp, 'vFCP', FormatDec(NFBDocumentLine."FCP Amount", 2, 2));
                    end;
                end;
            '10':
                begin
                    AddOwnIcms(Grp, NFBDocumentLine, false);
                    AddFcp(Grp, NFBDocumentLine);
                    AddIcmsSt(Grp, NFBDocumentLine);
                end;
            '20':
                begin
                    AddOwnIcms(Grp, NFBDocumentLine, true);
                    AddFcp(Grp, NFBDocumentLine);
                end;
            '30':
                AddIcmsSt(Grp, NFBDocumentLine);
            '40', '41', '50', '60':
                ;
            '51':
                if NFBDocumentLine."ICMS Base" <> 0 then
                    AddOwnIcms(Grp, NFBDocumentLine, NFBDocumentLine."ICMS Base Reduction %" <> 0);
            '70':
                begin
                    AddOwnIcms(Grp, NFBDocumentLine, true);
                    AddFcp(Grp, NFBDocumentLine);
                    AddIcmsSt(Grp, NFBDocumentLine);
                end;
            '90':
                begin
                    if NFBDocumentLine."ICMS Base" <> 0 then begin
                        AddText(Grp, 'modBC', '3');
                        AddText(Grp, 'vBC', FormatDec(NFBDocumentLine."ICMS Base", 2, 2));
                        if NFBDocumentLine."ICMS Base Reduction %" <> 0 then
                            AddText(Grp, 'pRedBC', FormatDec(NFBDocumentLine."ICMS Base Reduction %", 2, 4));
                        AddText(Grp, 'pICMS', FormatDec(NFBDocumentLine."ICMS %", 2, 4));
                        AddText(Grp, 'vICMS', FormatDec(NFBDocumentLine."ICMS Amount", 2, 2));
                        AddFcp(Grp, NFBDocumentLine);
                    end;
                    if NFBDocumentLine."ICMS ST Base" <> 0 then
                        AddIcmsSt(Grp, NFBDocumentLine);
                end;
        end;
    end;

    local procedure AddOwnIcms(var Grp: XmlElement; NFBDocumentLine: Record "NFB Document Line"; WithReduction: Boolean)
    begin
        AddText(Grp, 'modBC', '3');
        if WithReduction then
            AddText(Grp, 'pRedBC', FormatDec(NFBDocumentLine."ICMS Base Reduction %", 2, 4));
        AddText(Grp, 'vBC', FormatDec(NFBDocumentLine."ICMS Base", 2, 2));
        AddText(Grp, 'pICMS', FormatDec(NFBDocumentLine."ICMS %", 2, 4));
        AddText(Grp, 'vICMS', FormatDec(NFBDocumentLine."ICMS Amount", 2, 2));
    end;

    local procedure AddFcp(var Grp: XmlElement; NFBDocumentLine: Record "NFB Document Line")
    begin
        if NFBDocumentLine."FCP Amount" = 0 then
            exit;
        AddText(Grp, 'vBCFCP', FormatDec(DefaultDec(NFBDocumentLine."FCP Base", NFBDocumentLine."ICMS Base"), 2, 2));
        AddText(Grp, 'pFCP', FormatDec(NFBDocumentLine."FCP %", 2, 4));
        AddText(Grp, 'vFCP', FormatDec(NFBDocumentLine."FCP Amount", 2, 2));
    end;

    local procedure AddIcmsSt(var Grp: XmlElement; NFBDocumentLine: Record "NFB Document Line")
    begin
        if NFBDocumentLine."ICMS ST MVA %" <> 0 then begin
            AddText(Grp, 'modBCST', '4');
            AddText(Grp, 'pMVAST', FormatDec(NFBDocumentLine."ICMS ST MVA %", 2, 4));
        end else
            AddText(Grp, 'modBCST', '6');
        if NFBDocumentLine."ICMS ST Base Reduction %" <> 0 then
            AddText(Grp, 'pRedBCST', FormatDec(NFBDocumentLine."ICMS ST Base Reduction %", 2, 4));
        AddText(Grp, 'vBCST', FormatDec(NFBDocumentLine."ICMS ST Base", 2, 2));
        AddText(Grp, 'pICMSST', FormatDec(NFBDocumentLine."ICMS ST %", 2, 4));
        AddText(Grp, 'vICMSST', FormatDec(NFBDocumentLine."ICMS ST Amount", 2, 2));
        if NFBDocumentLine."FCP ST Amount" <> 0 then begin
            AddText(Grp, 'vBCFCPST', FormatDec(DefaultDec(NFBDocumentLine."FCP ST Base", NFBDocumentLine."ICMS ST Base"), 2, 2));
            AddText(Grp, 'pFCPST', FormatDec(NFBDocumentLine."FCP ST %", 2, 4));
            AddText(Grp, 'vFCPST', FormatDec(NFBDocumentLine."FCP ST Amount", 2, 2));
        end;
    end;

    local procedure AddIPI(var Imposto: XmlElement; NFBDocumentLine: Record "NFB Document Line")
    var
        IPI: XmlElement;
        Grp: XmlElement;
        CST: Text;
    begin
        CST := NFBValidation.OnlyDigits(NFBDocumentLine."IPI CST");
        if CST = '' then
            exit;
        IPI := AddGroup(Imposto, 'IPI');
        AddText(IPI, 'cEnq', DefaultText(NFBDocumentLine."IPI Enq. Code", '999'));
        if CST in ['00', '49', '50', '99'] then begin
            Grp := AddGroup(IPI, 'IPITrib');
            AddText(Grp, 'CST', CST);
            AddText(Grp, 'vBC', FormatDec(NFBDocumentLine."IPI Base", 2, 2));
            AddText(Grp, 'pIPI', FormatDec(NFBDocumentLine."IPI %", 2, 4));
            AddText(Grp, 'vIPI', FormatDec(NFBDocumentLine."IPI Amount", 2, 2));
        end else begin
            Grp := AddGroup(IPI, 'IPINT');
            AddText(Grp, 'CST', CST);
        end;
    end;

    local procedure AddII(var Imposto: XmlElement; NFBDocumentHeader: Record "NFB Document Header"; NFBDocumentLine: Record "NFB Document Line")
    var
        II: XmlElement;
    begin
        // The II group is required on imports (CFOP 3xxx) and not allowed otherwise.
        if CopyStr(NFBDocumentLine.CFOP, 1, 1) <> '3' then
            exit;
        II := AddGroup(Imposto, 'II');
        AddText(II, 'vBC', FormatDec(NFBDocumentLine."II Base", 2, 2));
        AddText(II, 'vDespAdu', FormatDec(NFBDocumentLine."II Customs Expenses", 2, 2));
        AddText(II, 'vII', FormatDec(NFBDocumentLine."II Amount", 2, 2));
        AddText(II, 'vIOF', FormatDec(NFBDocumentLine."IOF Amount", 2, 2));
    end;

    local procedure AddPisCofins(var Imposto: XmlElement; TaxName: Text; CSTCode: Code[2]; Base: Decimal; Rate: Decimal; Amount: Decimal)
    var
        Tax: XmlElement;
        Grp: XmlElement;
        CST: Text;
    begin
        CST := DefaultText(NFBValidation.OnlyDigits(CSTCode), '99');
        Tax := AddGroup(Imposto, TaxName);
        case CST of
            '01', '02':
                Grp := AddGroup(Tax, TaxName + 'Aliq');
            '04', '05', '06', '07', '08', '09':
                Grp := AddGroup(Tax, TaxName + 'NT');
            else
                Grp := AddGroup(Tax, TaxName + 'Outr');
        end;
        AddText(Grp, 'CST', CST);
        if CST in ['04', '05', '06', '07', '08', '09'] then
            exit;
        AddText(Grp, 'vBC', FormatDec(Base, 2, 2));
        AddText(Grp, 'p' + TaxName, FormatDec(Rate, 2, 4));
        AddText(Grp, 'v' + TaxName, FormatDec(Amount, 2, 2));
    end;

    local procedure AddICMSUFDest(var Imposto: XmlElement; NFBDocumentLine: Record "NFB Document Line")
    var
        Grp: XmlElement;
    begin
        if (NFBDocumentLine."DIFAL Dest. Amount" = 0) and (NFBDocumentLine."FCP Dest. Amount" = 0) then
            exit;
        Grp := AddGroup(Imposto, 'ICMSUFDest');
        AddText(Grp, 'vBCUFDest', FormatDec(NFBDocumentLine."DIFAL Base", 2, 2));
        AddText(Grp, 'vBCFCPUFDest', FormatDec(NFBDocumentLine."DIFAL Base", 2, 2));
        AddText(Grp, 'pFCPUFDest', FormatDec(NFBDocumentLine."FCP Dest. %", 2, 4));
        AddText(Grp, 'pICMSUFDest', FormatDec(NFBDocumentLine."DIFAL Internal %", 2, 4));
        AddText(Grp, 'pICMSInter', FormatDec(NFBDocumentLine."DIFAL Interstate %", 2, 2));
        AddText(Grp, 'pICMSInterPart', '100.00');
        AddText(Grp, 'vFCPUFDest', FormatDec(NFBDocumentLine."FCP Dest. Amount", 2, 2));
        AddText(Grp, 'vICMSUFDest', FormatDec(NFBDocumentLine."DIFAL Dest. Amount", 2, 2));
        AddText(Grp, 'vICMSUFRemet', '0.00');
    end;

    local procedure AddIBSCBS(var Imposto: XmlElement; NFBDocumentLine: Record "NFB Document Line")
    var
        IBSCBS: XmlElement;
        GIBSCBS: XmlElement;
        Grp: XmlElement;
    begin
        if NFBDocumentLine."IBS/CBS CST" = '' then
            exit;
        IBSCBS := AddGroup(Imposto, 'IBSCBS');
        AddText(IBSCBS, 'CST', NFBDocumentLine."IBS/CBS CST");
        AddText(IBSCBS, 'cClassTrib', NFBDocumentLine.cClassTrib);
        if NFBDocumentLine."IBS/CBS Base" = 0 then
            exit;
        GIBSCBS := AddGroup(IBSCBS, 'gIBSCBS');
        AddText(GIBSCBS, 'vBC', FormatDec(NFBDocumentLine."IBS/CBS Base", 2, 2));

        Grp := AddGroup(GIBSCBS, 'gIBSUF');
        AddText(Grp, 'pIBSUF', FormatDec(NFBDocumentLine."IBS UF %", 2, 4));
        AddReduction(Grp, NFBDocumentLine."IBS Reduction %", NFBDocumentLine."IBS UF %");
        AddText(Grp, 'vIBSUF', FormatDec(NFBDocumentLine."IBS UF Amount", 2, 2));

        Grp := AddGroup(GIBSCBS, 'gIBSMun');
        AddText(Grp, 'pIBSMun', FormatDec(NFBDocumentLine."IBS Mun. %", 2, 4));
        AddReduction(Grp, NFBDocumentLine."IBS Reduction %", NFBDocumentLine."IBS Mun. %");
        AddText(Grp, 'vIBSMun', FormatDec(NFBDocumentLine."IBS Mun. Amount", 2, 2));

        AddText(GIBSCBS, 'vIBS', FormatDec(NFBDocumentLine."IBS UF Amount" + NFBDocumentLine."IBS Mun. Amount", 2, 2));

        Grp := AddGroup(GIBSCBS, 'gCBS');
        AddText(Grp, 'pCBS', FormatDec(NFBDocumentLine."CBS %", 2, 4));
        AddReduction(Grp, NFBDocumentLine."CBS Reduction %", NFBDocumentLine."CBS %");
        AddText(Grp, 'vCBS', FormatDec(NFBDocumentLine."CBS Amount", 2, 2));
    end;

    local procedure AddReduction(var Grp: XmlElement; ReductionPct: Decimal; Rate: Decimal)
    var
        Red: XmlElement;
    begin
        if ReductionPct = 0 then
            exit;
        Red := AddGroup(Grp, 'gRed');
        AddText(Red, 'pRedAliq', FormatDec(ReductionPct, 2, 4));
        AddText(Red, 'pAliqEfet', FormatDec(Rate * (1 - ReductionPct / 100), 2, 4));
    end;

    local procedure AddTotal(var InfNFe: XmlElement; NFBDocumentHeader: Record "NFB Document Header")
    var
        Total: XmlElement;
        Tot: XmlElement;
        GIBS: XmlElement;
        Grp: XmlElement;
        VIBS: Decimal;
    begin
        Total := AddGroup(InfNFe, 'total');
        Tot := AddGroup(Total, 'ICMSTot');
        AddText(Tot, 'vBC', FormatDec(NFBDocumentHeader."ICMS Base", 2, 2));
        AddText(Tot, 'vICMS', FormatDec(NFBDocumentHeader."ICMS Amount", 2, 2));
        AddText(Tot, 'vICMSDeson', '0.00');
        if NFBDocumentHeader."FCP Dest. Amount" <> 0 then
            AddText(Tot, 'vFCPUFDest', FormatDec(NFBDocumentHeader."FCP Dest. Amount", 2, 2));
        if NFBDocumentHeader."DIFAL Dest. Amount" <> 0 then begin
            AddText(Tot, 'vICMSUFDest', FormatDec(NFBDocumentHeader."DIFAL Dest. Amount", 2, 2));
            AddText(Tot, 'vICMSUFRemet', '0.00');
        end;
        AddText(Tot, 'vFCP', FormatDec(NFBDocumentHeader."FCP Amount", 2, 2));
        AddText(Tot, 'vBCST', FormatDec(NFBDocumentHeader."ICMS ST Base", 2, 2));
        AddText(Tot, 'vST', FormatDec(NFBDocumentHeader."ICMS ST Amount", 2, 2));
        AddText(Tot, 'vFCPST', FormatDec(NFBDocumentHeader."FCP ST Amount", 2, 2));
        AddText(Tot, 'vFCPSTRet', '0.00');
        AddText(Tot, 'vProd', FormatDec(NFBDocumentHeader."Products Amount", 2, 2));
        AddText(Tot, 'vFrete', FormatDec(NFBDocumentHeader."Freight Amount", 2, 2));
        AddText(Tot, 'vSeg', FormatDec(NFBDocumentHeader."Insurance Amount", 2, 2));
        AddText(Tot, 'vDesc', FormatDec(NFBDocumentHeader."Discount Amount", 2, 2));
        AddText(Tot, 'vII', FormatDec(NFBDocumentHeader."II Amount", 2, 2));
        AddText(Tot, 'vIPI', FormatDec(NFBDocumentHeader."IPI Amount", 2, 2));
        AddText(Tot, 'vIPIDevol', '0.00');
        AddText(Tot, 'vPIS', FormatDec(NFBDocumentHeader."PIS Amount", 2, 2));
        AddText(Tot, 'vCOFINS', FormatDec(NFBDocumentHeader."COFINS Amount", 2, 2));
        AddText(Tot, 'vOutro', FormatDec(NFBDocumentHeader."Other Expenses", 2, 2));
        AddText(Tot, 'vNF', FormatDec(NFBDocumentHeader."Invoice Amount", 2, 2));

        if not NFBSetup."Include IBS/CBS Group" then
            exit;
        VIBS := NFBDocumentHeader."IBS UF Amount" + NFBDocumentHeader."IBS Mun. Amount";
        Tot := AddGroup(Total, 'IBSCBSTot');
        AddText(Tot, 'vBCIBSCBS', FormatDec(NFBDocumentHeader."IBS/CBS Base", 2, 2));
        GIBS := AddGroup(Tot, 'gIBS');
        Grp := AddGroup(GIBS, 'gIBSUF');
        AddText(Grp, 'vDif', '0.00');
        AddText(Grp, 'vDevTrib', '0.00');
        AddText(Grp, 'vIBSUF', FormatDec(NFBDocumentHeader."IBS UF Amount", 2, 2));
        Grp := AddGroup(GIBS, 'gIBSMun');
        AddText(Grp, 'vDif', '0.00');
        AddText(Grp, 'vDevTrib', '0.00');
        AddText(Grp, 'vIBSMun', FormatDec(NFBDocumentHeader."IBS Mun. Amount", 2, 2));
        AddText(GIBS, 'vIBS', FormatDec(VIBS, 2, 2));
        AddText(GIBS, 'vCredPres', '0.00');
        AddText(GIBS, 'vCredPresCondSus', '0.00');
        Grp := AddGroup(Tot, 'gCBS');
        AddText(Grp, 'vDif', '0.00');
        AddText(Grp, 'vDevTrib', '0.00');
        AddText(Grp, 'vCBS', FormatDec(NFBDocumentHeader."CBS Amount", 2, 2));
        AddText(Grp, 'vCredPres', '0.00');
        AddText(Grp, 'vCredPresCondSus', '0.00');
    end;

    local procedure AddTransp(var InfNFe: XmlElement; NFBDocumentHeader: Record "NFB Document Header")
    var
        NFBDocumentTransport: Record "NFB Document Transport";
        Transp: XmlElement;
        Grp: XmlElement;
        Digits: Text;
    begin
        Transp := AddGroup(InfNFe, 'transp');
        if not NFBDocumentTransport.Get(NFBDocumentHeader."No.") then begin
            AddText(Transp, 'modFrete', '9');
            exit;
        end;
        AddText(Transp, 'modFrete', Format(NFBDocumentTransport."Freight Mode".AsInteger()));
        if (NFBDocumentTransport."Carrier Name" <> '') or (NFBDocumentTransport."Carrier CPF/CNPJ" <> '') then begin
            Grp := AddGroup(Transp, 'transporta');
            Digits := NFBValidation.OnlyDigits(NFBDocumentTransport."Carrier CPF/CNPJ");
            case StrLen(Digits) of
                14:
                    AddText(Grp, 'CNPJ', Digits);
                11:
                    AddText(Grp, 'CPF', Digits);
            end;
            AddOptText(Grp, 'xNome', Clean(NFBDocumentTransport."Carrier Name", 60));
            AddOptText(Grp, 'IE', NFBValidation.OnlyDigits(NFBDocumentTransport."Carrier IE"));
            AddOptText(Grp, 'xEnder', Clean(NFBDocumentTransport."Carrier Address", 60));
            AddOptText(Grp, 'xMun', Clean(NFBDocumentTransport."Carrier City", 60));
            AddOptText(Grp, 'UF', NFBDocumentTransport."Carrier UF");
        end;
        if (NFBDocumentTransport."Vehicle Plate" <> '') and (NFBDocumentHeader."Destination Id" = NFBDocumentHeader."Destination Id"::Internal) then begin
            Grp := AddGroup(Transp, 'veicTransp');
            AddText(Grp, 'placa', NFBDocumentTransport."Vehicle Plate");
            AddOptText(Grp, 'UF', NFBDocumentTransport."Vehicle UF");
        end;
        if (NFBDocumentTransport."Volume Quantity" <> 0) or (NFBDocumentTransport."Gross Weight" <> 0) then begin
            Grp := AddGroup(Transp, 'vol');
            if NFBDocumentTransport."Volume Quantity" <> 0 then
                AddText(Grp, 'qVol', Format(NFBDocumentTransport."Volume Quantity"));
            AddOptText(Grp, 'esp', Clean(NFBDocumentTransport."Volume Kind", 60));
            AddOptText(Grp, 'marca', Clean(NFBDocumentTransport.Brand, 60));
            if NFBDocumentTransport."Net Weight" <> 0 then
                AddText(Grp, 'pesoL', FormatDec(NFBDocumentTransport."Net Weight", 3, 3));
            if NFBDocumentTransport."Gross Weight" <> 0 then
                AddText(Grp, 'pesoB', FormatDec(NFBDocumentTransport."Gross Weight", 3, 3));
        end;
    end;

    local procedure AddCobr(var InfNFe: XmlElement; NFBDocumentHeader: Record "NFB Document Header")
    var
        NFBDocumentInstallment: Record "NFB Document Installment";
        Cobr: XmlElement;
        Fat: XmlElement;
        Dup: XmlElement;
        Total: Decimal;
    begin
        NFBDocumentInstallment.SetRange("Document No.", NFBDocumentHeader."No.");
        if NFBDocumentInstallment.IsEmpty() then
            exit;
        NFBDocumentInstallment.CalcSums(Amount);
        Total := NFBDocumentInstallment.Amount;
        Cobr := AddGroup(InfNFe, 'cobr');
        Fat := AddGroup(Cobr, 'fat');
        AddText(Fat, 'nFat', Format(NFBDocumentHeader."NF No."));
        AddText(Fat, 'vOrig', FormatDec(Total, 2, 2));
        AddText(Fat, 'vDesc', '0.00');
        AddText(Fat, 'vLiq', FormatDec(Total, 2, 2));
        NFBDocumentInstallment.FindSet();
        repeat
            Dup := AddGroup(Cobr, 'dup');
            AddText(Dup, 'nDup', NFBDocumentInstallment."Installment No.");
            AddText(Dup, 'dVenc', FormatDate(NFBDocumentInstallment."Due Date"));
            AddText(Dup, 'vDup', FormatDec(NFBDocumentInstallment.Amount, 2, 2));
        until NFBDocumentInstallment.Next() = 0;
    end;

    local procedure AddPag(var InfNFe: XmlElement; NFBDocumentHeader: Record "NFB Document Header")
    var
        NFBDocumentPayment: Record "NFB Document Payment";
        Pag: XmlElement;
        DetPag: XmlElement;
        Card: XmlElement;
        Change: Decimal;
    begin
        Pag := AddGroup(InfNFe, 'pag');
        NFBDocumentPayment.SetRange("Document No.", NFBDocumentHeader."No.");
        if not NFBDocumentPayment.FindSet() then begin
            DetPag := AddGroup(Pag, 'detPag');
            AddText(DetPag, 'tPag', '90');
            AddText(DetPag, 'vPag', '0.00');
            exit;
        end;
        repeat
            DetPag := AddGroup(Pag, 'detPag');
            AddText(DetPag, 'indPag', Format(NFBDocumentPayment."Payment Indicator", 0, 2));
            AddText(DetPag, 'tPag', DefaultText(NFBDocumentPayment."Payment Type", '99'));
            if NFBDocumentPayment."Payment Type" = '99' then
                AddText(DetPag, 'xPag', DefaultText(Clean(NFBDocumentPayment.Description, 60), 'Outros'));
            AddText(DetPag, 'vPag', FormatDec(NFBDocumentPayment.Amount, 2, 2));
            if (NFBDocumentPayment."Payment Type" in ['03', '04', '17']) and (NFBDocumentPayment."Card Integration" <> NFBDocumentPayment."Card Integration"::" ") then begin
                Card := AddGroup(DetPag, 'card');
                AddText(Card, 'tpIntegra', Format(NFBDocumentPayment."Card Integration", 0, 2));
                AddOptText(Card, 'CNPJ', NFBValidation.OnlyDigits(NFBDocumentPayment."Card Acquirer CNPJ"));
                AddOptText(Card, 'tBand', NFBDocumentPayment."Card Brand");
                AddOptText(Card, 'cAut', NFBDocumentPayment."Card Authorization");
            end;
            Change += NFBDocumentPayment.Change;
        until NFBDocumentPayment.Next() = 0;
        if Change <> 0 then
            AddText(Pag, 'vTroco', FormatDec(Change, 2, 2));
    end;

    local procedure AddInfAdic(var InfNFe: XmlElement; NFBDocumentHeader: Record "NFB Document Header")
    var
        InfAdic: XmlElement;
        FiscalInfo: Text;
        AdditionalInfo: Text;
    begin
        FiscalInfo := Clean(NFBDocumentHeader."Fiscal Info", 2000);
        AdditionalInfo := Clean(NFBDocumentHeader."Additional Info", 5000);
        if (FiscalInfo = '') and (AdditionalInfo = '') then
            exit;
        InfAdic := AddGroup(InfNFe, 'infAdic');
        AddOptText(InfAdic, 'infAdFisco', FiscalInfo);
        AddOptText(InfAdic, 'infCpl', AdditionalInfo);
    end;

    local procedure AddExporta(var InfNFe: XmlElement; NFBDocumentHeader: Record "NFB Document Header")
    var
        Exporta: XmlElement;
    begin
        if (NFBDocumentHeader."Destination Id" <> NFBDocumentHeader."Destination Id"::Exterior) or (NFBDocumentHeader."Export Shipping UF" = '') then
            exit;
        Exporta := AddGroup(InfNFe, 'exporta');
        AddText(Exporta, 'UFSaidaPais', NFBDocumentHeader."Export Shipping UF");
        AddText(Exporta, 'xLocExporta', Clean(NFBDocumentHeader."Export Shipping Place", 60));
    end;

    local procedure AddInfRespTec(var InfNFe: XmlElement)
    var
        RespTec: XmlElement;
    begin
        if NFBSetup."Resp. Tech. CNPJ" = '' then
            exit;
        RespTec := AddGroup(InfNFe, 'infRespTec');
        AddText(RespTec, 'CNPJ', NFBValidation.OnlyDigits(NFBSetup."Resp. Tech. CNPJ"));
        AddText(RespTec, 'xContato', Clean(NFBSetup."Resp. Tech. Contact", 60));
        AddText(RespTec, 'email', Clean(NFBSetup."Resp. Tech. E-Mail", 60));
        AddText(RespTec, 'fone', NFBValidation.OnlyDigits(NFBSetup."Resp. Tech. Phone"));
    end;

    local procedure AddGroup(var Parent: XmlElement; Name: Text) Child: XmlElement
    begin
        Child := XmlElement.Create(Name, NamespaceUri());
        Parent.Add(Child);
    end;

    local procedure AddText(var Parent: XmlElement; Name: Text; Value: Text)
    var
        Child: XmlElement;
    begin
        Child := XmlElement.Create(Name, NamespaceUri(), Value);
        Parent.Add(Child);
    end;

    local procedure AddOptText(var Parent: XmlElement; Name: Text; Value: Text)
    begin
        if Value <> '' then
            AddText(Parent, Name, Value);
    end;

    local procedure AddOptAmount(var Parent: XmlElement; Name: Text; Value: Decimal)
    begin
        if Value <> 0 then
            AddText(Parent, Name, FormatDec(Value, 2, 2));
    end;

    /// <summary>
    /// Formats a decimal with a dot separator and between MinDecimals and MaxDecimals decimal places, as the NF-e schema requires.
    /// </summary>
    procedure FormatDec(Value: Decimal; MinDecimals: Integer; MaxDecimals: Integer): Text
    var
        Factor: Decimal;
        IntegerPart: Decimal;
        Fraction: Decimal;
        FractionText: Text;
        Result: Text;
        IsNegative: Boolean;
    begin
        // Built by hand so the result never depends on the user's regional settings.
        Factor := Power(10, MaxDecimals);
        Value := Round(Value, 1 / Factor);
        IsNegative := Value < 0;
        Value := Abs(Value);
        IntegerPart := Round(Value, 1, '<');
        Fraction := Round((Value - IntegerPart) * Factor, 1);
        Result := Format(IntegerPart, 0, 9);
        if MaxDecimals > 0 then begin
            FractionText := NFBAccessKeyMgt.PadNumber(Format(Fraction, 0, 9), MaxDecimals);
            while (StrLen(FractionText) > MinDecimals) and (CopyStr(FractionText, StrLen(FractionText), 1) = '0') do
                FractionText := CopyStr(FractionText, 1, StrLen(FractionText) - 1);
            if FractionText <> '' then
                Result += '.' + FractionText;
        end;
        if IsNegative and (Result.Replace('0', '').Replace('.', '') <> '') then
            Result := '-' + Result;
        exit(Result);
    end;

    procedure FormatDate(Value: Date): Text
    begin
        exit(Format(Value, 0, '<Year4>-<Month,2>-<Day,2>'));
    end;

    /// <summary>
    /// Formats a DateTime as AAAA-MM-DDThh:mm:ssTZD in the offset of NF-e Setup (Brasília, -03:00, by default),
    /// independently of the time zone of the user or the service.
    /// </summary>
    procedure FormatDateTimeTZ(Value: DateTime): Text
    var
        UtcText: Text;
        Offset: Text;
        LocalDate: Date;
        Seconds: Integer;
        OffsetSeconds: Integer;
        Year: Integer;
        Month: Integer;
        Day: Integer;
        Hours: Integer;
        Minutes: Integer;
        Secs: Integer;
    begin
        if Value = 0DT then
            Value := CurrentDateTime();
        if not NFBSetup.Get() then
            NFBSetup.Init();
        Offset := NFBSetup."UTC Offset";
        if StrLen(Offset) <> 6 then
            Offset := '-03:00';
        // Format 9 returns the value in UTC: YYYY-MM-DDThh:mm:ss[.fff]Z
        UtcText := Format(Value, 0, 9);
        Evaluate(Year, CopyStr(UtcText, 1, 4));
        Evaluate(Month, CopyStr(UtcText, 6, 2));
        Evaluate(Day, CopyStr(UtcText, 9, 2));
        Evaluate(Hours, CopyStr(UtcText, 12, 2));
        Evaluate(Minutes, CopyStr(UtcText, 15, 2));
        Evaluate(Secs, CopyStr(UtcText, 18, 2));
        Evaluate(OffsetSeconds, CopyStr(Offset, 2, 2));
        OffsetSeconds := OffsetSeconds * 3600;
        OffsetSeconds += GetOffsetMinutes(Offset) * 60;
        if CopyStr(Offset, 1, 1) = '-' then
            OffsetSeconds := -OffsetSeconds;
        LocalDate := DMY2Date(Day, Month, Year);
        Seconds := Hours * 3600 + Minutes * 60 + Secs + OffsetSeconds;
        while Seconds < 0 do begin
            Seconds += 86400;
            LocalDate := LocalDate - 1;
        end;
        while Seconds >= 86400 do begin
            Seconds -= 86400;
            LocalDate := LocalDate + 1;
        end;
        exit(StrSubstNo('%1T%2:%3:%4%5', FormatDate(LocalDate),
            NFBAccessKeyMgt.PadNumber(Format(Seconds div 3600), 2),
            NFBAccessKeyMgt.PadNumber(Format((Seconds mod 3600) div 60), 2),
            NFBAccessKeyMgt.PadNumber(Format(Seconds mod 60), 2),
            Offset));
    end;

    local procedure GetOffsetMinutes(Offset: Text) Result: Integer
    begin
        if not Evaluate(Result, CopyStr(Offset, 5, 2)) then
            Result := 0;
    end;

    /// <summary>
    /// Trims, removes line breaks and control characters, collapses repeated spaces and cuts to MaxLength.
    /// </summary>
    procedure Clean(Value: Text; MaxLength: Integer): Text
    var
        Result: Text;
        Ch: Char;
        I: Integer;
        LastWasSpace: Boolean;
    begin
        for I := 1 to StrLen(Value) do begin
            Ch := Value[I];
            if Ch < 32 then
                Ch := 32;
            if Ch = 32 then begin
                if not LastWasSpace then
                    Result += ' ';
                LastWasSpace := true;
            end else begin
                Result += Format(Ch);
                LastWasSpace := false;
            end;
        end;
        exit(CopyStr(Result.Trim(), 1, MaxLength));
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

    local procedure BoolText(Value: Boolean): Text
    begin
        if Value then
            exit('1');
        exit('0');
    end;

    local procedure IIf(Condition: Boolean; TrueValue: Text; FalseValue: Text): Text
    begin
        if Condition then
            exit(TrueValue);
        exit(FalseValue);
    end;

    local procedure MaxInt(Value: Integer; Minimum: Integer): Integer
    begin
        if Value < Minimum then
            exit(Minimum);
        exit(Value);
    end;
}
