# NF-e Brasil para Business Central

Extensão AL (prefixo `NFB`, IDs 50100–50199) que adiciona ao Business Central 26 W1 on-premises os cadastros fiscais, o cálculo e a contabilização dos tributos brasileiros e o documento fiscal NF-e modelo 55.

Estão entregues a **fase 1** (cadastros, impostos, contabilização e documento fiscal), a **fase 2** (XML, validação XSD, arquivos, DANFE e relatório por período), a **fase 3** (emissão pelo PlugNotas e modo arquivo) e a **fase 5** (apuração mensal dos tributos e títulos a pagar das guias). A fase 4 (transmissão direta à SEFAZ com assinatura no BC) ficou fora desta versão.

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

## O que a fase 3 entrega

| Área | Objetos |
|---|---|
| Interface de provedor | Interface NFB IFiscal Provider, implementada pelo enum NFB Issue Mode (50101): File Only, SEFAZ Direct (fase 4) e PlugNotas |
| PlugNotas | Codeunits NFB PlugNotas Payload (50121, JSON), NFB PlugNotas Client (50122, REST) e NFB PlugNotas Provider (50123) |
| Modo arquivo | Codeunit NFB File Provider (50117) e importação do XML autorizado (nfeProc) e de eventos (procEventoNFe) |
| Eventos | Tabela NFB Document Event (50120), página NFB Document Events (50122), página de diálogo NFB Event Dialog (50117) e enum NFB Event Type (50115) |
| Orquestração | Codeunit NFB Provider Mgt (50116), com envio, consulta, cancelamento, CC-e e importação |
| Fila de tarefas | Codeunit NFB Job Queue Handler (50119), que consulta as NF-e enviadas e os eventos pendentes |
| SEFAZ direto | Codeunit NFB SEFAZ Provider (50118), só com o aviso de que a opção chega na fase 4 |
| Atualização | Codeunit NFB Upgrade (50124), que preenche os campos novos do Setup em instalações existentes |

### Configurar o PlugNotas

1. No **NF-e Setup**, escolha **Issue Mode = PlugNotas**.
2. No grupo **PlugNotas**:
   - **Use PlugNotas Sandbox** marcado usa `https://api.sandbox.plugnotas.com.br`, que simula as respostas e não exige contrato. Sem API Key, usa a chave pública de testes da TecnoSpeed.
   - Desmarcado usa `https://api.plugnotas.com.br`. Nesse caso o campo **Environment** do Setup decide entre homologação e produção da SEFAZ (vai no JSON como `config.producao`).
   - **API Key** é a chave do portal PlugNotas. Ela fica no isolated storage do BC, não na tabela.
   - **Provider URL** só precisa ser preenchido para usar outro endereço.
3. Cadastre o certificado A1 e a empresa emitente no portal ou na API do PlugNotas. Sandbox e API real têm cadastros separados.
4. Use **Test Connection** no Setup. Ele consulta a empresa no PlugNotas e mostra se o servidor do BC alcança a API. Se der erro de conexão, libere a saída do servidor do BC para o host do PlugNotas no firewall.
5. Use **Create Status Query Job** para criar a tarefa recorrente que consulta as notas enviadas e os eventos pendentes (intervalo em **Status Query Interval**).

Ao atualizar uma instalação existente, a codeunit NFB Upgrade (50124) liga **Use PlugNotas Sandbox** e define o intervalo de consulta em 5 minutos, para que nenhuma chamada vá à API real por engano.

### Emitir pelo PlugNotas

1. No **NF-e Monitor** ou no cartão, **Send** valida a nota, gera o XML (e a validação XSD, se ativa), monta o JSON, guarda o JSON em **Files** e envia para o PlugNotas. O status passa a **Sent**.
2. O PlugNotas processa de forma assíncrona. **Query Status** (ou a tarefa da fila) consulta o resultado:
   - autorizada: status **Authorized**, protocolo gravado, XML autorizado e DANFE em PDF do PlugNotas guardados em **Files**;
   - rejeitada: status **Rejected** com o motivo. Corrija e use **Send** de novo. O número da nota é mantido; o `idIntegracao` ganha um sufixo (`-2`, `-3`) porque o PlugNotas exige que seja único.
3. **Cancel NF-e** pede a justificativa (15 a 255 caracteres) e envia o cancelamento. **Correction Letter (CC-e)** pede o texto da correção (15 a 1000 caracteres). Os dois ficam em **Events** e são consultados até serem registrados. Um cancelamento registrado muda a nota para **Cancelled**.
4. **Download DANFE (PDF)** baixa o DANFE do PlugNotas. Se ele não existir, imprime o DANFE da extensão.

### Modo arquivo (File Only)

**Send** gera e baixa o XML sem assinatura para outro sistema transmitir. Depois, **Import Authorized XML** importa o XML autorizado (`nfeProc`) ou o XML de um evento (`procEventoNFe`). A nota é encontrada pela chave de acesso, o status é atualizado pelo cStat e o arquivo fica em **Files**.

### Pontos a conferir no sandbox

A documentação completa do PlugNotas (Swagger) não pôde ser lida no ambiente onde o código foi escrito. Os nomes dos campos seguem os exemplos oficiais da TecnoSpeed para a reforma tributária (`github.com/tecnospeed/Arquivos_RTC`) e a documentação pública. Estes pontos não foram confirmados e devem ser testados no sandbox antes de produção:

- o grupo do transportador (`transporte.transportadora` com `cpfCnpj` e `razaoSocial`);
- o grupo de cobrança (`cobranca.fatura` e `cobranca.parcelas`);
- a estrutura de importação (`itens[].importacao`, com DI e imposto de importação) e de exportação (`exportacao`);
- o campo do destinatário estrangeiro (`destinatario.idEstrangeiro`);
- o status `DENEGADO`, que a extensão trata como denegação, e o cStat devolvido em cada consulta.

## O que a fase 5 entrega

- **Apuração mensal** (NF-e Tax Settlements): uma apuração por mês, com uma linha por tributo e, para ST, FCP ST, DIFAL e FCP de destino devidos a outra UF, uma linha por UF.
- **Calculate** soma os tributos das faturas e notas de crédito de venda e de compra lançadas no mês. Entram só os documentos cujo tipo de operação calcula e contabiliza tributos, e só os tributos que o Tax Posting Setup contabilizou: débitos nas vendas (conta a recolher) e créditos nas compras (conta a recuperar). Assim a apuração bate com o saldo das contas. Notas de crédito entram com sinal negativo.
- O **saldo credor** da última apuração lançada é transportado para o mês seguinte. Na primeira apuração, o saldo credor inicial pode ser digitado na linha (ele já deve estar na conta a recuperar). **Outros débitos** e **outros créditos** são ajustes manuais, lançados contra a conta de ajuste.
- **Post** lança, num único registro contábil, o débito da conta a recolher, o crédito da conta a recuperar (créditos usados) e o título a pagar: um movimento de fornecedor por guia, com vencimento, para o fornecedor que representa o órgão (Receita Federal, SEFAZ-RJ ou SEFAZ de outra UF). O crédito que sobra fica na conta a recuperar.
- **Tax Due Date Setup**: por tributo (e, se quiser, por UF) define a guia (DARF, DARJ, GNRE), o código de receita, o fornecedor, o dia de vencimento, quantos meses depois do período, o que fazer em fim de semana ou feriado (antecipar, postergar ou manter) e o calendário base com os feriados.
- **Reopen** reabre uma apuração lançada depois que o registro contábil dela foi estornado (G/L Registers, **Reverse Register**). Só a última apuração lançada pode ser reaberta. As apurações seguem a ordem dos meses: um mês só é lançado depois do anterior, e reabrir um mês obriga a recalcular os meses seguintes que estiverem abertos.
- **Documents** mostra cada documento que entrou na apuração; **Payables** abre os títulos criados; **Print** imprime o relatório de apuração por período (NF-e Tax Settlement).

### Configurar a apuração

1. No **NF-e Setup**, grupo Tax Settlement, preencha a numeração das apurações e um modelo e lote de diário geral. O lançamento não grava linhas no lote; o modelo e o lote ficam nos movimentos para que o registro possa ser estornado pelo Reverse Register, e o código de origem vem do modelo.
2. Cadastre os fornecedores dos órgãos (Receita Federal, SEFAZ-RJ e as SEFAZ das UFs em que houver ST ou DIFAL a recolher) com grupo de lançamento de fornecedor.
3. Em **Tax Due Date Setup**, informe o fornecedor de cada tributo e confira os dados carregados por padrão: IPI (DARF 5123), PIS (DARF 8109) e COFINS (DARF 2172) vencem no dia 25 do mês seguinte, antecipando se não for dia útil; DIFAL e FCP de destino (GNRE) no dia 15. O vencimento do ICMS, FCP e ST do RJ depende da atividade e ficou em 0: preencha o dia ou digite o vencimento na linha da apuração. Para uma UF com regra própria, crie uma linha com o tributo e a UF.
4. Se houver outros débitos ou créditos, informe a conta de ajuste no Tax Due Date Setup ou na linha.

### Apurar um mês

1. Em **NF-e Tax Settlements**, crie uma apuração e informe qualquer data do mês em Starting Date.
2. Use **Calculate**. Recalcule sempre que lançar mais documentos do mês; os ajustes digitados nas linhas são mantidos.
3. Confira as linhas, os documentos e os vencimentos, e use **Post**.

Os pagamentos das guias seguem o fluxo normal de contas a pagar do BC (diário de pagamentos aplicado ao título).

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

A fase 5 usou IDs livres nas duas extensões: tabelas 50121–50124, páginas 50123–50127, codeunit 50125, relatório 50103 e enums 50116–50117. Ao criar objetos nas próximas fases, confira os IDs já usados pelas duas extensões antes de escolher um número livre.

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
- Sem transmissão direta à SEFAZ nem assinatura digital no BC (fase 4). O XML gerado sai sem assinatura; a validação XSD insere uma assinatura fictícia só para conferir o restante do documento. Pelo PlugNotas, quem assina é o próprio PlugNotas.
- Inutilização de numeração ainda não está implementada.
- O PlugNotas é consultado por polling (fila de tarefas), sem webhook.
- O DANFE imprime uma NF-e por execução, com os dados do cabeçalho na primeira página.
- O código de barras do DANFE usa a fonte IDAutomationC128S. Ela precisa estar instalada no servidor do BC para que o PDF saia com o código de barras.
- A validação XSD usa .NET (System.Xml) e grava os schemas numa pasta temporária do servidor, por isso só funciona on-premises.
- Os grupos IBS/CBS seguem a NT 2025.002 v1.30. Se a SEFAZ da UF ainda não aceitar esses grupos, desmarque **Include IBS/CBS Group** no Setup.
- Emitentes do Simples Nacional e MEI não são suportados no XML (CSOSN), pois o emitente é do regime normal.
- Lucro Presumido: PIS e COFINS cumulativos, sem crédito nas compras.
- A apuração não gera o arquivo nem o código de barras das guias (DARF, DARJ, GNRE): ela cria o título a pagar, e a guia é emitida no portal do órgão.
- A apuração não cobre a escrituração fiscal (SPED EFD ICMS/IPI e EFD Contribuições).
- IBS e CBS de 2026 são informativos (ano de teste) e não têm vencimento padrão. Se o Tax Posting Setup contabilizar esses tributos, eles aparecem na apuração e precisam de fornecedor e vencimento, ou a linha deve ser excluída antes de lançar.
- O DIFAL nas compras para uso e consumo segue o que o Tax Posting Setup lançou (crédito na conta a recuperar, se houver) e precisa ser conferido pelo contador.
- Remessas de transferência não entram na apuração, porque não contabilizam tributos.
