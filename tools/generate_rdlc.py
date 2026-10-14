"""Generates the RDLC layouts of the NF-e reports.

Run from the repository root:  python3 tools/generate_rdlc.py
Edit the box lists below and run again instead of editing the .rdlc files by hand.
"""
import uuid
from xml.sax.saxutils import escape

NS = 'http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition'
RD = 'http://schemas.microsoft.com/SQLServer/reporting/reportdesigner'
FONT = 'Arial'
BARCODE_FONT = 'IDAutomationC128S'
counter = [0]


def name(prefix):
    counter[0] += 1
    return f'{prefix}{counter[0]}'


def first(field):
    return f'=First(Fields!{field}.Value, "DataSet_Result")'


def border(style='Solid'):
    return f'<Border><Color>Black</Color><Style>{style}</Style><Width>0.5pt</Width></Border>'


def run(value, size, bold=False, color=None, font=FONT):
    weight = '<FontWeight>Bold</FontWeight>' if bold else ''
    col = f'<Color>{color}</Color>' if color else ''
    if value.startswith('='):
        val = f'<Value>{escape(value)}</Value>'
    else:
        val = f'<Value>{escape(value)}</Value>'
    return (f'<TextRun>{val}<Style><FontFamily>{font}</FontFamily><FontSize>{size}pt</FontSize>'
            f'{weight}{col}</Style></TextRun>')


def paragraph(runs, align='Left'):
    return f'<Paragraph><TextRuns>{"".join(runs)}</TextRuns><Style><TextAlign>{align}</TextAlign></Style></Paragraph>'


def textbox(left, top, width, height, paragraphs, boxed=True, can_grow=False, hidden=None, valign='Top', tb_name=None):
    n = tb_name or name('Textbox')
    vis = f'<Visibility><Hidden>{escape(hidden)}</Hidden></Visibility>' if hidden else ''
    grow = '<CanGrow>true</CanGrow>' if can_grow else '<CanGrow>false</CanGrow>'
    bord = border() if boxed else '<Border><Style>None</Style></Border>'
    return (f'<Textbox Name="{n}">{grow}<KeepTogether>true</KeepTogether>'
            f'<Paragraphs>{"".join(paragraphs)}</Paragraphs>'
            f'<Top>{top}cm</Top><Left>{left}cm</Left><Height>{height}cm</Height><Width>{width}cm</Width>{vis}'
            f'<Style>{bord}<VerticalAlign>{valign}</VerticalAlign><PaddingLeft>2pt</PaddingLeft><PaddingRight>2pt</PaddingRight>'
            f'<PaddingTop>1pt</PaddingTop><PaddingBottom>1pt</PaddingBottom></Style></Textbox>')


def field_box(left, top, width, height, caption, expr, size=7, align='Left', bold=False, can_grow=False):
    """A DANFE cell: small caption on top, value below."""
    return textbox(left, top, width, height,
                   [paragraph([run(caption, 5)]), paragraph([run(expr, size, bold)], align)],
                   can_grow=can_grow)


def label(left, top, width, text, size=6, bold=True):
    return textbox(left, top, width, 0.35, [paragraph([run(text, size, bold)])], boxed=False)


def tablix(name_, left, top, columns, header_height, row_height, filter_expr=None):
    """columns: list of (width_cm, caption, expression, align)."""
    cols = ''.join(f'<TablixColumn><Width>{w}cm</Width></TablixColumn>' for w, _, _, _ in columns)

    def cell(text, size, bold, align, boxed=True):
        n = name('TableCell')
        return (f'<TablixCell><CellContents><Textbox Name="{n}"><CanGrow>true</CanGrow><KeepTogether>true</KeepTogether>'
                f'<Paragraphs>{paragraph([run(text, size, bold)], align)}</Paragraphs>'
                f'<Style>{border()}<VerticalAlign>Middle</VerticalAlign><PaddingLeft>2pt</PaddingLeft><PaddingRight>2pt</PaddingRight>'
                f'<PaddingTop>1pt</PaddingTop><PaddingBottom>1pt</PaddingBottom></Style></Textbox></CellContents></TablixCell>')

    header_cells = ''.join(cell(c, 5, True, 'Center') for _, c, _, _ in columns)
    detail_cells = ''.join(cell(e, 6, False, a) for _, _, e, a in columns)
    width = round(sum(w for w, _, _, _ in columns), 3)
    col_members = ''.join('<TablixMember />' for _ in columns)
    filters = ''
    if filter_expr:
        filters = (f'<Filters><Filter><FilterExpression>{escape(filter_expr[0])}</FilterExpression><Operator>{filter_expr[1]}</Operator>'
                   f'<FilterValues><FilterValue>{escape(filter_expr[2])}</FilterValue></FilterValues></Filter></Filters>')
    return (f'<Tablix Name="{name_}"><TablixBody><TablixColumns>{cols}</TablixColumns><TablixRows>'
            f'<TablixRow><Height>{header_height}cm</Height><TablixCells>{header_cells}</TablixCells></TablixRow>'
            f'<TablixRow><Height>{row_height}cm</Height><TablixCells>{detail_cells}</TablixCells></TablixRow>'
            f'</TablixRows></TablixBody>'
            f'<TablixColumnHierarchy><TablixMembers>{col_members}</TablixMembers></TablixColumnHierarchy>'
            f'<TablixRowHierarchy><TablixMembers>'
            f'<TablixMember><KeepWithGroup>After</KeepWithGroup><RepeatOnNewPage>true</RepeatOnNewPage></TablixMember>'
            f'<TablixMember><Group Name="{name_}_Details" /></TablixMember>'
            f'</TablixMembers></TablixRowHierarchy>'
            f'<DataSetName>DataSet_Result</DataSetName>{filters}'
            f'<Top>{top}cm</Top><Left>{left}cm</Left><Height>{round(header_height + row_height, 3)}cm</Height><Width>{width}cm</Width>'
            f'<Style><Border><Style>None</Style></Border></Style></Tablix>')


def report(items, fields, body_height, page_width=21, page_height=29.7, margin=0.5, orientation_width=20):
    fields_xml = ''.join(f'<Field Name="{f}"><DataField>{f}</DataField></Field>' for f in fields)
    return ('<?xml version="1.0" encoding="utf-8"?>\n'
            f'<Report xmlns="{NS}" xmlns:rd="{RD}">'
            '<AutoRefresh>0</AutoRefresh>'
            '<DataSources><DataSource Name="DataSource"><ConnectionProperties><DataProvider>SQL</DataProvider><ConnectString />'
            f'</ConnectionProperties><rd:SecurityType>None</rd:SecurityType><rd:DataSourceID>{uuid.uuid4()}</rd:DataSourceID></DataSource></DataSources>'
            '<ReportSections><ReportSection><Body>'
            f'<ReportItems>{"".join(items)}</ReportItems><Height>{body_height}cm</Height><Style /></Body>'
            f'<Width>{orientation_width}cm</Width>'
            f'<Page><PageHeight>{page_height}cm</PageHeight><PageWidth>{page_width}cm</PageWidth>'
            f'<LeftMargin>{margin}cm</LeftMargin><RightMargin>{margin}cm</RightMargin><TopMargin>{margin}cm</TopMargin><BottomMargin>{margin}cm</BottomMargin>'
            '<Style /></Page></ReportSection></ReportSections>'
            '<Language>=User!Language</Language><ConsumeContainerWhitespace>true</ConsumeContainerWhitespace>'
            f'<rd:ReportUnitType>Cm</rd:ReportUnitType><rd:ReportID>{uuid.uuid4()}</rd:ReportID>'
            f'<DataSets><DataSet Name="DataSet_Result"><Fields>{fields_xml}</Fields>'
            '<Query><DataSourceName>DataSource</DataSourceName><CommandText /></Query></DataSet></DataSets>'
            '</Report>\n')


# ---------------------------------------------------------------- DANFE
DANFE_HEADER_FIELDS = [
    'DocumentNo', 'NFNo', 'Series', 'TpNF', 'AccessKeyFormatted', 'AccessKeyBarcode', 'ProtocolText', 'NatOp',
    'IssuerName', 'IssuerAddress1', 'IssuerAddress2', 'IssuerAddress3', 'IssuerIE', 'IssuerIEST', 'IssuerCNPJ', 'StubText',
    'RecipientName', 'RecipientDoc', 'RecipientAddress', 'RecipientDistrict', 'RecipientPostCode', 'RecipientCity',
    'RecipientPhone', 'RecipientUF', 'RecipientIE', 'IssueDate', 'ExitDate', 'ExitTime', 'InstallmentsText',
    'ICMSBase', 'ICMSAmount', 'STBase', 'STAmount', 'IIAmount', 'FCPAmount', 'FCPDestAmount', 'DIFALDestAmount',
    'PISAmount', 'COFINSAmount', 'ProductsAmount', 'FreightAmount', 'InsuranceAmount', 'DiscountAmount', 'OtherExpenses',
    'IPIAmount', 'InvoiceAmount', 'IBSCBSBase', 'IBSUFAmount', 'IBSMunAmount', 'CBSAmount', 'FreightModeText',
    'CarrierName', 'CarrierDoc', 'CarrierIE', 'CarrierAddress', 'CarrierCity', 'CarrierUF', 'VehiclePlate', 'VehicleUF',
    'VolumeQuantity', 'VolumeKind', 'VolumeBrand', 'GrossWeight', 'NetWeight', 'AdditionalInfo', 'FiscalInfo',
    'IsHomologation', 'NotAuthorized']
DANFE_LINE_FIELDS = [
    'LineCode', 'LineDescription', 'LineNCM', 'LineCST', 'LineCFOP', 'LineUnit', 'LineQuantity', 'LineUnitPrice',
    'LineAmount', 'LineDiscount', 'LineICMSBase', 'LineICMSAmount', 'LineIPIAmount', 'LineICMSPct', 'LineIPIPct']


def danfe():
    f = first
    items = []
    W = 20.0
    y = 0.0
    # Receipt stub (canhoto)
    items.append(textbox(0, y, 16, 0.8, [paragraph([run(f('StubText'), 5.5)])]))
    items.append(field_box(0, y + 0.8, 4, 0.8, 'DATA DE RECEBIMENTO', ''))
    items.append(field_box(4, y + 0.8, 12, 0.8, 'IDENTIFICAÇÃO E ASSINATURA DO RECEBEDOR', ''))
    items.append(textbox(16, y, 4, 1.6, [
        paragraph([run('NF-e', 10, True)], 'Center'),
        paragraph([run('="Nº " & ' + f('NFNo')[1:], 8, True)], 'Center'),
        paragraph([run('="SÉRIE " & ' + f('Series')[1:], 8, True)], 'Center')], valign='Middle'))
    y = 1.75
    items.append(textbox(0, y, W, 0.1, [paragraph([run('', 2)])], boxed=False))
    items.append(f'<Line Name="{name("Line")}"><Top>{y + 0.05}cm</Top><Left>0cm</Left><Height>0cm</Height><Width>{W}cm</Width>'
                 '<Style><Border><Color>Black</Color><Style>Dashed</Style><Width>0.5pt</Width></Border></Style></Line>')
    y = 2.0
    # Issuer, DANFE box, access key
    items.append(textbox(0, y, 8, 3.2, [
        paragraph([run('IDENTIFICAÇÃO DO EMITENTE', 5)]),
        paragraph([run(f('IssuerName'), 10, True)], 'Center'),
        paragraph([run(f('IssuerAddress1'), 7)], 'Center'),
        paragraph([run(f('IssuerAddress2'), 7)], 'Center'),
        paragraph([run(f('IssuerAddress3'), 7)], 'Center')]))
    items.append(textbox(8, y, 3.5, 3.2, [
        paragraph([run('DANFE', 12, True)], 'Center'),
        paragraph([run('DOCUMENTO AUXILIAR DA NOTA FISCAL ELETRÔNICA', 6)], 'Center'),
        paragraph([run('0 - ENTRADA', 6)], 'Left'),
        paragraph([run('1 - SAÍDA', 6)], 'Left'),
        paragraph([run('="TIPO: " & ' + f('TpNF')[1:], 8, True)], 'Center'),
        paragraph([run('="Nº " & ' + f('NFNo')[1:], 8, True)], 'Center'),
        paragraph([run('="SÉRIE " & ' + f('Series')[1:], 8, True)], 'Center'),
        paragraph([run('="FOLHA " & Globals!PageNumber & "/" & Globals!TotalPages', 7)], 'Center')]))
    items.append(textbox(11.5, y, 8.5, 1.2, [paragraph([run(f('AccessKeyBarcode'), 22, font=BARCODE_FONT)], 'Center')], valign='Middle'))
    items.append(field_box(11.5, y + 1.2, 8.5, 0.8, 'CHAVE DE ACESSO', f('AccessKeyFormatted'), 8, 'Center', True))
    items.append(textbox(11.5, y + 2.0, 8.5, 1.2, [paragraph([run(
        'Consulta de autenticidade no portal nacional da NF-e www.nfe.fazenda.gov.br/portal ou no site da Sefaz Autorizadora', 7)], 'Center')],
        valign='Middle'))
    y += 3.2
    items.append(field_box(0, y, 11.5, 0.75, 'NATUREZA DA OPERAÇÃO', f('NatOp'), 8))
    items.append(field_box(11.5, y, 8.5, 0.75, 'PROTOCOLO DE AUTORIZAÇÃO DE USO', f('ProtocolText'), 8, 'Center'))
    y += 0.75
    items.append(field_box(0, y, 6.5, 0.75, 'INSCRIÇÃO ESTADUAL', f('IssuerIE'), 8))
    items.append(field_box(6.5, y, 6.5, 0.75, 'INSCRIÇÃO ESTADUAL DO SUBST. TRIBUT.', f('IssuerIEST'), 8))
    items.append(field_box(13, y, 7, 0.75, 'CNPJ', f('IssuerCNPJ'), 8))
    y += 0.85
    # Recipient
    items.append(label(0, y, W, 'DESTINATÁRIO / REMETENTE'))
    y += 0.35
    items.append(field_box(0, y, 12, 0.75, 'NOME / RAZÃO SOCIAL', f('RecipientName'), 8))
    items.append(field_box(12, y, 5, 0.75, 'CNPJ / CPF', f('RecipientDoc'), 8))
    items.append(field_box(17, y, 3, 0.75, 'DATA DA EMISSÃO', f('IssueDate'), 8, 'Center'))
    y += 0.75
    items.append(field_box(0, y, 9.5, 0.75, 'ENDEREÇO', f('RecipientAddress'), 8))
    items.append(field_box(9.5, y, 5, 0.75, 'BAIRRO / DISTRITO', f('RecipientDistrict'), 8))
    items.append(field_box(14.5, y, 2.5, 0.75, 'CEP', f('RecipientPostCode'), 8))
    items.append(field_box(17, y, 3, 0.75, 'DATA DA SAÍDA/ENTRADA', f('ExitDate'), 8, 'Center'))
    y += 0.75
    items.append(field_box(0, y, 7, 0.75, 'MUNICÍPIO', f('RecipientCity'), 8))
    items.append(field_box(7, y, 4, 0.75, 'FONE / FAX', f('RecipientPhone'), 8))
    items.append(field_box(11, y, 1.5, 0.75, 'UF', f('RecipientUF'), 8, 'Center'))
    items.append(field_box(12.5, y, 4.5, 0.75, 'INSCRIÇÃO ESTADUAL', f('RecipientIE'), 8))
    items.append(field_box(17, y, 3, 0.75, 'HORA DA SAÍDA/ENTRADA', f('ExitTime'), 8, 'Center'))
    y += 0.85
    # Installments
    items.append(label(0, y, W, 'FATURA / DUPLICATAS'))
    y += 0.35
    items.append(textbox(0, y, W, 0.6, [paragraph([run(f('InstallmentsText'), 7)])], can_grow=True))
    y += 0.7
    # Taxes
    items.append(label(0, y, W, 'CÁLCULO DO IMPOSTO'))
    y += 0.35
    row1 = [('BASE DE CÁLC. DO ICMS', 'ICMSBase'), ('VALOR DO ICMS', 'ICMSAmount'), ('BASE DE CÁLC. ICMS S.T.', 'STBase'),
            ('VALOR DO ICMS SUBST.', 'STAmount'), ('V. IMP. IMPORTAÇÃO', 'IIAmount'), ('VALOR DO FCP', 'FCPAmount'),
            ('V. FCP UF DEST.', 'FCPDestAmount'), ('VALOR DO PIS', 'PISAmount'), ('V. TOTAL PRODUTOS', 'ProductsAmount')]
    row2 = [('VALOR DO FRETE', 'FreightAmount'), ('VALOR DO SEGURO', 'InsuranceAmount'), ('DESCONTO', 'DiscountAmount'),
            ('OUTRAS DESPESAS', 'OtherExpenses'), ('VALOR TOTAL IPI', 'IPIAmount'), ('V. ICMS UF DEST.', 'DIFALDestAmount'),
            ('VALOR DA COFINS', 'COFINSAmount'), ('V. TOTAL DA NOTA', 'InvoiceAmount')]
    for row in (row1, row2):
        width = W / len(row)
        for i, (cap, fld) in enumerate(row):
            items.append(field_box(round(i * width, 3), y, round(width, 3), 0.75, cap, f(fld), 7, 'Right', fld == 'InvoiceAmount'))
        y += 0.75
    row3 = [('BASE DE CÁLC. IBS/CBS', 'IBSCBSBase'), ('VALOR DO IBS UF', 'IBSUFAmount'), ('VALOR DO IBS MUNICIPAL', 'IBSMunAmount'),
            ('VALOR DA CBS', 'CBSAmount')]
    for i, (cap, fld) in enumerate(row3):
        items.append(field_box(i * 5, y, 5, 0.75, cap, f(fld), 7, 'Right'))
    y += 0.85
    # Transport
    items.append(label(0, y, W, 'TRANSPORTADOR / VOLUMES TRANSPORTADOS'))
    y += 0.35
    items.append(field_box(0, y, 7, 0.75, 'RAZÃO SOCIAL', f('CarrierName'), 7))
    items.append(field_box(7, y, 4, 0.75, 'FRETE POR CONTA', f('FreightModeText'), 6))
    items.append(field_box(11, y, 2.5, 0.75, 'PLACA DO VEÍCULO', f('VehiclePlate'), 7))
    items.append(field_box(13.5, y, 1, 0.75, 'UF', f('VehicleUF'), 7, 'Center'))
    items.append(field_box(14.5, y, 5.5, 0.75, 'CNPJ / CPF', f('CarrierDoc'), 7))
    y += 0.75
    items.append(field_box(0, y, 9, 0.75, 'ENDEREÇO', f('CarrierAddress'), 7))
    items.append(field_box(9, y, 4.5, 0.75, 'MUNICÍPIO', f('CarrierCity'), 7))
    items.append(field_box(13.5, y, 1, 0.75, 'UF', f('CarrierUF'), 7, 'Center'))
    items.append(field_box(14.5, y, 5.5, 0.75, 'INSCRIÇÃO ESTADUAL', f('CarrierIE'), 7))
    y += 0.75
    vol = [('QUANTIDADE', 'VolumeQuantity', 3), ('ESPÉCIE', 'VolumeKind', 4), ('MARCA', 'VolumeBrand', 4),
           ('PESO BRUTO', 'GrossWeight', 4.5), ('PESO LÍQUIDO', 'NetWeight', 4.5)]
    x = 0
    for cap, fld, w in vol:
        items.append(field_box(x, y, w, 0.75, cap, f(fld), 7, 'Right' if 'Weight' in fld else 'Left'))
        x += w
    y += 0.85
    # Products
    items.append(label(0, y, W, 'DADOS DOS PRODUTOS / SERVIÇOS'))
    y += 0.35
    cols = [(1.6, 'CÓDIGO', '=Fields!LineCode.Value', 'Left'),
            (5.0, 'DESCRIÇÃO DO PRODUTO / SERVIÇO', '=Fields!LineDescription.Value', 'Left'),
            (1.3, 'NCM/SH', '=Fields!LineNCM.Value', 'Center'),
            (0.8, 'O/CST', '=Fields!LineCST.Value', 'Center'),
            (0.8, 'CFOP', '=Fields!LineCFOP.Value', 'Center'),
            (0.8, 'UN', '=Fields!LineUnit.Value', 'Center'),
            (1.4, 'QUANT.', '=Fields!LineQuantity.Value', 'Right'),
            (1.5, 'VALOR UNIT.', '=Fields!LineUnitPrice.Value', 'Right'),
            (1.5, 'VALOR TOTAL', '=Fields!LineAmount.Value', 'Right'),
            (1.4, 'B. CÁLC. ICMS', '=Fields!LineICMSBase.Value', 'Right'),
            (1.2, 'VALOR ICMS', '=Fields!LineICMSAmount.Value', 'Right'),
            (1.0, 'VALOR IPI', '=Fields!LineIPIAmount.Value', 'Right'),
            (0.7, 'ALÍQ. ICMS', '=Fields!LineICMSPct.Value', 'Right'),
            (0.0, '', '', 'Right')]
    cols = [c for c in cols if c[0] > 0]
    total_w = sum(c[0] for c in cols)
    # stretch the description so the table is exactly the page width
    cols[1] = (round(cols[1][0] + (W - total_w), 3),) + cols[1][1:]
    items.append(tablix('ProductsTable', 0, y, cols, 0.6, 0.45, ('=Fields!LineCode.Value', 'NotEqual', '=""')))
    y += 1.05 + 0.15
    # Additional info (pushed down when the products table grows)
    items.append(label(0, y, W, 'DADOS ADICIONAIS'))
    y += 0.35
    items.append(textbox(0, y, 13, 2.5, [paragraph([run('INFORMAÇÕES COMPLEMENTARES', 5)]),
                                         paragraph([run(f('AdditionalInfo'), 7)])], can_grow=True))
    items.append(textbox(13, y, 7, 2.5, [paragraph([run('RESERVADO AO FISCO', 5)])]))
    y += 2.5
    # Watermark for homologation or not-authorized documents
    items.append(textbox(2, 9.5, 16, 1.5, [paragraph([run('SEM VALOR FISCAL', 40, True, '#FF0000')], 'Center')], boxed=False,
                         hidden='=IIF(CStr(First(Fields!IsHomologation.Value, "DataSet_Result")) = "True" Or '
                                'CStr(First(Fields!NotAuthorized.Value, "DataSet_Result")) = "True", False, True)'))
    return report(items, DANFE_HEADER_FIELDS + DANFE_LINE_FIELDS, round(y, 3))


# ---------------------------------------------------------------- NF-e by period
PERIOD_FIELDS = ['CompanyName', 'FilterText', 'DocumentNo', 'NFNo', 'Series', 'IssueDate', 'Status', 'Direction', 'CFOPText',
                 'RecipientName', 'RecipientDoc', 'AccessKey', 'InvoiceAmount', 'ICMSAmount', 'STAmount', 'IPIAmount',
                 'PISAmount', 'COFINSAmount', 'IBSAmount', 'CBSAmount',
                 'InvoiceAmountNum', 'ICMSAmountNum', 'STAmountNum', 'IPIAmountNum', 'PISAmountNum', 'COFINSAmountNum',
                 'IBSAmountNum', 'CBSAmountNum']


def period():
    items = []
    W = 27.7
    items.append(textbox(0, 0, W, 0.6, [paragraph([run('NF-e emitidas por período', 12, True)])], boxed=False))
    items.append(textbox(0, 0.6, W, 0.5, [paragraph([run(first('CompanyName'), 8)])], boxed=False))
    items.append(textbox(0, 1.1, W, 0.5, [paragraph([run(first('FilterText'), 7)])], boxed=False, can_grow=True))
    cols = [(1.6, 'NÚMERO', '=Fields!NFNo.Value', 'Right'),
            (0.8, 'SÉRIE', '=Fields!Series.Value', 'Center'),
            (1.6, 'EMISSÃO', '=Fields!IssueDate.Value', 'Center'),
            (1.8, 'STATUS', '=Fields!Status.Value', 'Left'),
            (1.2, 'TIPO', '=Fields!Direction.Value', 'Left'),
            (1.0, 'CFOP', '=Fields!CFOPText.Value', 'Center'),
            (5.0, 'DESTINATÁRIO / REMETENTE', '=Fields!RecipientName.Value', 'Left'),
            (2.6, 'CNPJ / CPF', '=Fields!RecipientDoc.Value', 'Left'),
            (2.0, 'VALOR TOTAL', '=Fields!InvoiceAmount.Value', 'Right'),
            (1.6, 'ICMS', '=Fields!ICMSAmount.Value', 'Right'),
            (1.4, 'ICMS ST', '=Fields!STAmount.Value', 'Right'),
            (1.4, 'IPI', '=Fields!IPIAmount.Value', 'Right'),
            (1.4, 'PIS', '=Fields!PISAmount.Value', 'Right'),
            (1.5, 'COFINS', '=Fields!COFINSAmount.Value', 'Right'),
            (1.2, 'IBS', '=Fields!IBSAmount.Value', 'Right'),
            (1.2, 'CBS', '=Fields!CBSAmount.Value', 'Right')]
    total_w = sum(c[0] for c in cols)
    cols[6] = (round(cols[6][0] + (W - total_w), 3),) + cols[6][1:]
    items.append(tablix('DocumentsTable', 0, 1.8, cols, 0.6, 0.45))
    totals = [('TOTAL DAS NOTAS', 'InvoiceAmountNum'), ('ICMS', 'ICMSAmountNum'), ('ICMS ST', 'STAmountNum'),
              ('IPI', 'IPIAmountNum'), ('PIS', 'PISAmountNum'), ('COFINS', 'COFINSAmountNum'), ('IBS', 'IBSAmountNum'),
              ('CBS', 'CBSAmountNum')]
    width = W / len(totals)
    for i, (cap, fld) in enumerate(totals):
        items.append(field_box(round(i * width, 3), 3.1, round(width, 3), 0.75, cap,
                               f'=Format(Sum(Fields!{fld}.Value, "DataSet_Result"), "#,##0.00")', 8, 'Right', True))
    return report(items, PERIOD_FIELDS, 4.0, page_width=29.7, page_height=21, margin=1, orientation_width=W)


if __name__ == '__main__':
    with open('src/Reports/Layouts/NFBDANFE.rdlc', 'w', encoding='utf-8') as fh:
        fh.write(danfe())
    counter[0] = 0
    with open('src/Reports/Layouts/NFBNFeByPeriod.rdlc', 'w', encoding='utf-8') as fh:
        fh.write(period())
    print('layouts written')
