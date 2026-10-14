# NF-e Brasil para Business Central

Extensão AL (prefixo `NFB`, IDs 50100–50199) que adiciona ao Business Central 26 W1 on-premises os cadastros fiscais, o cálculo e a contabilização dos tributos brasileiros e o documento fiscal NF-e modelo 55.

Estão entregues a **fase 1** (cadastros, impostos, contabilização e documento fiscal) e a **fase 2** (XML, validação XSD, arquivos, DANFE e relatório por período). As fases seguintes (PlugNotas, SEFAZ direto com assinatura, apuração e contas a pagar dos tributos) ainda não estão implementadas.

> **Atenção:** o código não foi compilado no ambiente onde foi escrito, porque os símbolos do BC não estavam acessíveis. Antes de publicar, compile no VS Code com os símbolos do seu BC 26 (`AL: Download symbols` e depois `AL: Package`) e corrija o que o compilador apontar.

## O que a fase 1 entrega

| Área | Objetos |
|---|---|
| Configuração | NFB Setup, NFB Series, NFB Tax Posting Setup |
| Tabelas de referência | Municípios IBGE, NCM, CFOP, cClassTrib (com importação CSV) |
| Regras fiscais | NFB Operation Type (tipo de operação), NFB Tax Rule (regras de ICMS, FCP, ST, DIFAL, IPI, PIS, COFINS, IBS, CBS) |
| Cadastros | Campos fiscais em Company Information, Customer, Vendor, Ship-to Address, Location, Item, Unit of Measure, Country/Region, Payment Method, Shipping Agent |
| Documentos | Campos NF-e em pedidos, faturas, notas de crédito e devoluções de venda e compra, transferências e documentos lançados |
| Motor de impostos | Codeunit NFB Tax Engine, com resultado gravado na tabela NFB Tax Line |
| Contabilização | Codeunit NFB Tax Posting, que gera linhas de conta contábil antes do lançamento |
| Documento fiscal | NFB Document Header/Line e tabelas filhas, monitor de NF-e, numeração, chave de acesso e validação |

## O que a fase 2 entrega

| Área | Objetos |
|---|---|
| XML da NF-e | Codeunit NFB XML Builder (50113): XML layout 4.00 sem assinatura, com os grupos de IBS/CBS da NT 2025.002 v1.30 |
| Validação XSD | Codeunit NFB XSD Validator (50114) e tabela/página NFB XSD Schema(s) (50119/50121) para importar o pacote de schemas da SEFAZ |
| Arquivos | Tabela NFB Document File (50118), página NFB Document Files (50120), codeunit NFB File Mgt (50115) e enum NFB File Type (50114) |
| Exportação | Download do XML de uma nota, ZIP das notas selecionadas e relatório NFB Export XML Batch (50102), que gera um ZIP por período |
| DANFE | Relatório NFB DANFE (50100), layout RDLC retrato com código de barras CODE-128C da chave de acesso |
| Relatório | NFB NF-e by Period (50101), lista paisagem com totais de ICMS, ST, IPI, PIS, COFINS, IBS e CBS |

### Como usar

1. No **NF-e Setup**, grupo **XML**, marque **Validate XSD** se quiser conferir cada XML contra o schema, ajuste o fuso (**UTC Offset**, padrão -03:00) e preencha o **Responsável técnico** (infRespTec), que é obrigatório para algumas UFs.
2. Para validar contra o XSD, abra **XSD Schemas** e use **Import Schemas** com o pacote ZIP de schemas publicado no Portal da NF-e (por exemplo `PL_010_V1.30.zip`). O arquivo `nfe_v4.00.xsd` é marcado como schema principal.
3. No **NF-e Monitor** ou no cartão da NF-e, use **Generate XML**. A ação valida a nota, monta o XML, confere com o XSD (se configurado), grava o arquivo `<chave>-nfe.xml` em **Files** e muda o status para **XML Generated**. A ação pode ser repetida enquanto a nota não for transmitida; cada execução guarda um novo arquivo.
4. **Download XML** baixa o XML mais recente. **Export XML (ZIP)** baixa um ZIP com as notas selecionadas, e **Export XML by Period** faz o mesmo para um período.
5. **Print DANFE** imprime o DANFE. Enquanto a nota não for autorizada (fase 3 ou 4), o DANFE sai com a marca "SEM VALOR FISCAL".
6. **NF-e by Period** (em Relatórios do NF-e Monitor ou pela busca) lista as notas de um período com os totais.

O XML gerado segue o layout da SEFAZ e pode ser assinado e transmitido por qualquer emissor. A assinatura digital fica para a fase 4.

Os layouts RDLC são gerados pelo script `tools/generate_rdlc.py` (`python3 tools/generate_rdlc.py` na raiz do projeto). Para mudar o visual do DANFE, altere o script e gere de novo, ou edite o `.rdlc` direto no Report Builder.

## Fluxo

1. O usuário escolhe o **tipo de operação** no documento (há um padrão no Setup e no cliente ou fornecedor). Ele define natureza da operação, CFOP, finalidade e se a NF-e é emitida.
2. **Calculate NF-e Taxes** calcula os tributos de cada linha pela regra fiscal mais específica que se aplica. O cálculo é refeito no lançamento.
3. No lançamento, a extensão insere linhas de sistema de conta contábil com os tributos, conforme o **Tax Posting Setup**:
   - tributos fora do preço (IPI, ST, FCP ST, II) entram como uma linha que soma ao total;
   - tributos dentro do preço (ICMS, PIS, COFINS, IBS, CBS) entram como um par, débito na conta de dedução e crédito na conta de tributo a recolher, sem alterar o total;
   - nas compras, os créditos vão para a conta de tributo a recuperar, em contrapartida ao custo.
4. Depois do lançamento, a extensão cria o documento NF-e (se **Auto Create Document** estiver marcado no Setup) ou o usuário usa **Create NF-e** no documento lançado.
5. No **NF-e Monitor**, **Validate** confere os dados, atribui número e série e gera a chave de acesso. O status passa a Validated.

Origens suportadas: fatura e nota de crédito de venda, fatura de compra (importação ou NF-e de entrada própria), nota de crédito de compra (devolução de compra) e remessa de transferência.

## IDs e convivência com outras extensões

A extensão usa a faixa 50100–50199, que também é usada pelas extensões Academia2026 (50100–50149) e BC-CustomerFollowUp (50150–50199) publicadas no mesmo servidor. O BC só recusa a publicação quando o mesmo tipo de objeto usa o mesmo ID em duas extensões, ou quando duas extensões da mesma tabela usam o mesmo ID de campo. Por isso, só os objetos da NF-e Brasil que coincidiam com IDs já usados foram renumerados:

| Objeto | ID antigo | ID novo | Conflitava com |
|---|---|---|---|
| codeunit NFB Operation Mgt | 50100 | 50111 | Academia2026 |
| codeunit NFB Tax Engine | 50101 | 50112 | Academia2026Plus |
| page NFB Setup | 50100 | 50119 | CalculadoraMMCMDC |
| table NFB Document Transport | 50114 | 50117 | ABC Vehicle |
| tableextension NFB Location | 50113 | 50126 | ABC Customer Ext |
| pageextension NFB Sales Order | 50110 | 50135 | CustomerListExt |
| pageextension NFB Sales Invoice | 50111 | 50136 | MyBusinessManagerExt |
| pageextension NFB Sales Credit Memo | 50112 | 50137 | CustomerCardViaCEPExt |
| pageextension NFB Sales Return Order | 50113 | 50138 | ABC Customer Card Ext |
| pageextension NFB Posted Sales Credit Memos | 50120 | 50139 | UsingAPI |
| campo NFB Person Type (Customer) | 50100 | 50108 | ABC Vehicle No. (Academia2026) |

Ao criar objetos nas próximas fases, confira os IDs já usados pelas duas extensões antes de escolher um número livre.

## Configuração inicial

1. Publique e instale a extensão. A instalação carrega os dados padrão: CFOPs principais, 15 tipos de operação, regras de exemplo e o município do Rio de Janeiro. Também é possível usar **Load Default Data** no NF-e Setup. No Role Center **Business Manager**, o menu **NF-e Setup** reúne todas as páginas de configuração. Atribua o conjunto de permissões **NFB All** aos usuários que vão usar a extensão.
2. Em **Company Information**, preencha CNPJ, IE, IM, CNAE, regime tributário e endereço com código IBGE do município.
3. Importe as tabelas de referência pelas ações **Import CSV** (arquivos separados por `;` com linha de cabeçalho):
   - Municípios: `código IBGE;nome;UF`
   - NCM: `NCM;descrição;CEST;% IPI;Ex TIPI`
   - CFOP: `CFOP;descrição;devolução (0/1)`
   - cClassTrib: `cClassTrib;CST;descrição;% redução IBS;% redução CBS`
4. Crie as **contas contábeis de tributos** (a recolher, dedução, a recuperar) e preencha o **Tax Posting Setup**. As contas devem usar grupos de lançamento de IVA com 0%, para que o IVA do W1 não incida sobre as linhas de tributo.
5. Revise as **regras fiscais**. As alíquotas carregadas são exemplos (ICMS interno RJ 18% + FCP 2%, interestadual 12%, PIS 0,65%, COFINS 3%, CBS 0,9% e IBS UF 0,1% em 2026) e devem ser conferidas pelo contador.
6. Preencha os campos fiscais dos clientes, fornecedores, itens (NCM, origem, cClassTrib) e formas de pagamento (tPag).
7. Configure a série no **NFB Series** e a numeração do documento no Setup.

## Limitações conhecidas

- DIFAL calculado apenas com base única.
- Devolução de compra usa a nota de crédito de compra. A remessa de devolução não gera NF-e.
- Os indicadores (cues) do Role Center ficaram para uma fase seguinte.
- Sem transmissão nem assinatura digital. O XML sai sem assinatura; a validação XSD insere uma assinatura fictícia só para conferir o restante do documento.
- O DANFE imprime uma NF-e por execução, com os dados do cabeçalho na primeira página.
- O código de barras do DANFE usa a fonte IDAutomationC128S. Ela precisa estar instalada no servidor do BC para que o PDF saia com o código de barras.
- A validação XSD usa .NET (System.Xml) e grava os schemas numa pasta temporária do servidor, por isso só funciona on-premises.
- Os grupos IBS/CBS seguem a NT 2025.002 v1.30. Se a SEFAZ da UF ainda não aceitar esses grupos, desmarque **Include IBS/CBS Group** no Setup.
- Emitentes do Simples Nacional e MEI não são suportados no XML (CSOSN), pois o emitente é do regime normal.
- Lucro Presumido: PIS e COFINS cumulativos, sem crédito nas compras.
