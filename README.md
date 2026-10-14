# NF-e Brasil para Business Central

Extensão AL (prefixo `NFB`, IDs 50200–50399, fora das faixas da Academia2026 e da BC-CustomerFollowUp) que adiciona ao Business Central 26 W1 on-premises os cadastros fiscais, o cálculo e a contabilização dos tributos brasileiros e o documento fiscal NF-e modelo 55.

Esta entrega cobre a **fase 1** do plano. As fases seguintes (XML e DANFE, PlugNotas, SEFAZ direto, apuração e contas a pagar dos tributos) ainda não estão implementadas.

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

## Faixa de IDs

A extensão usa a faixa **50200–50399**. A faixa original era 50100–50199, mas a publicação falhou com o erro "The application object of type 'Table' with the ID '50114' is defined in multiple apps", porque ela já é ocupada por outras extensões publicadas no mesmo servidor:

| Extensão | Faixa |
|---|---|
| Academia2026 | 50100–50149 |
| BC-CustomerFollowUp | 50150–50199 |
| NF-e Brasil | 50200–50399 |

Todos os objetos e os campos das extensões de tabela foram renumerados somando 100 ao ID original (por exemplo, a tabela 50114 passou a ser 50214). Novos objetos das próximas fases devem ficar dentro de 50200–50399.

## Configuração inicial

1. Publique e instale a extensão. A instalação carrega os dados padrão: CFOPs principais, 15 tipos de operação, regras de exemplo e o município do Rio de Janeiro. Também é possível usar **Load Default Data** no NF-e Setup. Atribua o conjunto de permissões **NFB All** aos usuários que vão usar a extensão.
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
- Sem geração de XML, DANFE ou transmissão nesta fase. O modo de emissão no Setup já existe, mas só "File Only" terá efeito a partir da fase 2.
- Lucro Presumido: PIS e COFINS cumulativos, sem crédito nas compras.
