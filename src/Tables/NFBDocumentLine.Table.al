table 50110 "NFB Document Line"
{
    Caption = 'NF-e Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "NFB Document Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Item Seq."; Integer)
        {
            Caption = 'Item Sequence (nItem)';
        }
        field(4; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
        }
        // prod
        field(10; "Product Code"; Code[60])
        {
            Caption = 'Product Code (cProd)';
        }
        field(11; GTIN; Code[14])
        {
            Caption = 'GTIN (cEAN)';
        }
        field(12; Description; Text[120])
        {
            Caption = 'Description (xProd)';
        }
        field(13; NCM; Code[8])
        {
            Caption = 'NCM';
            TableRelation = "NFB NCM";
        }
        field(14; CEST; Code[7])
        {
            Caption = 'CEST';
        }
        field(15; "Ex TIPI"; Code[3])
        {
            Caption = 'Ex TIPI';
        }
        field(16; CFOP; Code[4])
        {
            Caption = 'CFOP';
            TableRelation = "NFB CFOP";
        }
        field(17; "Commercial Unit"; Code[6])
        {
            Caption = 'Commercial Unit (uCom)';
        }
        field(18; "Commercial Quantity"; Decimal)
        {
            Caption = 'Commercial Quantity (qCom)';
            DecimalPlaces = 0 : 4;
        }
        field(19; "Commercial Unit Price"; Decimal)
        {
            Caption = 'Commercial Unit Price (vUnCom)';
            DecimalPlaces = 2 : 10;
        }
        field(20; "Products Amount"; Decimal)
        {
            Caption = 'Gross Amount (vProd)';
            AutoFormatType = 1;
        }
        field(21; "Taxable Unit"; Code[6])
        {
            Caption = 'Taxable Unit (uTrib)';
        }
        field(22; "Taxable Quantity"; Decimal)
        {
            Caption = 'Taxable Quantity (qTrib)';
            DecimalPlaces = 0 : 4;
        }
        field(23; "Taxable Unit Price"; Decimal)
        {
            Caption = 'Taxable Unit Price (vUnTrib)';
            DecimalPlaces = 2 : 10;
        }
        field(24; "Freight Amount"; Decimal)
        {
            Caption = 'Freight (vFrete)';
            AutoFormatType = 1;
        }
        field(25; "Insurance Amount"; Decimal)
        {
            Caption = 'Insurance (vSeg)';
            AutoFormatType = 1;
        }
        field(26; "Discount Amount"; Decimal)
        {
            Caption = 'Discount (vDesc)';
            AutoFormatType = 1;
        }
        field(27; "Other Expenses"; Decimal)
        {
            Caption = 'Other Expenses (vOutro)';
            AutoFormatType = 1;
        }
        field(28; "Include in Total"; Boolean)
        {
            Caption = 'Include in Total (indTot)';
            InitValue = true;
        }
        field(29; Origin; Enum "NFB Goods Origin")
        {
            Caption = 'Origin (orig)';
        }
        // ICMS
        field(30; "ICMS CST"; Code[3])
        {
            Caption = 'ICMS CST';
        }
        field(31; "ICMS Base Reduction %"; Decimal)
        {
            Caption = 'ICMS Base Reduction % (pRedBC)';
            DecimalPlaces = 0 : 4;
        }
        field(32; "ICMS Base"; Decimal)
        {
            Caption = 'ICMS Base (vBC)';
            AutoFormatType = 1;
        }
        field(33; "ICMS %"; Decimal)
        {
            Caption = 'ICMS % (pICMS)';
            DecimalPlaces = 0 : 4;
        }
        field(34; "ICMS Amount"; Decimal)
        {
            Caption = 'ICMS (vICMS)';
            AutoFormatType = 1;
        }
        field(35; "FCP Base"; Decimal)
        {
            Caption = 'FCP Base (vBCFCP)';
            AutoFormatType = 1;
        }
        field(36; "FCP %"; Decimal)
        {
            Caption = 'FCP % (pFCP)';
            DecimalPlaces = 0 : 4;
        }
        field(37; "FCP Amount"; Decimal)
        {
            Caption = 'FCP (vFCP)';
            AutoFormatType = 1;
        }
        field(38; "ICMS ST MVA %"; Decimal)
        {
            Caption = 'ICMS ST MVA % (pMVAST)';
            DecimalPlaces = 0 : 4;
        }
        field(39; "ICMS ST Base Reduction %"; Decimal)
        {
            Caption = 'ICMS ST Base Reduction % (pRedBCST)';
            DecimalPlaces = 0 : 4;
        }
        field(40; "ICMS ST Base"; Decimal)
        {
            Caption = 'ICMS ST Base (vBCST)';
            AutoFormatType = 1;
        }
        field(41; "ICMS ST %"; Decimal)
        {
            Caption = 'ICMS ST % (pICMSST)';
            DecimalPlaces = 0 : 4;
        }
        field(42; "ICMS ST Amount"; Decimal)
        {
            Caption = 'ICMS ST (vICMSST)';
            AutoFormatType = 1;
        }
        field(43; "FCP ST Base"; Decimal)
        {
            Caption = 'FCP ST Base (vBCFCPST)';
            AutoFormatType = 1;
        }
        field(44; "FCP ST %"; Decimal)
        {
            Caption = 'FCP ST % (pFCPST)';
            DecimalPlaces = 0 : 4;
        }
        field(45; "FCP ST Amount"; Decimal)
        {
            Caption = 'FCP ST (vFCPST)';
            AutoFormatType = 1;
        }
        field(46; "DIFAL Base"; Decimal)
        {
            Caption = 'DIFAL Base (vBCUFDest)';
            AutoFormatType = 1;
        }
        field(47; "DIFAL Internal %"; Decimal)
        {
            Caption = 'Destination Internal % (pICMSUFDest)';
            DecimalPlaces = 0 : 4;
        }
        field(48; "DIFAL Interstate %"; Decimal)
        {
            Caption = 'Interstate % (pICMSInter)';
            DecimalPlaces = 0 : 4;
        }
        field(49; "DIFAL Dest. Amount"; Decimal)
        {
            Caption = 'DIFAL Destination (vICMSUFDest)';
            AutoFormatType = 1;
        }
        field(50; "FCP Dest. %"; Decimal)
        {
            Caption = 'FCP Destination % (pFCPUFDest)';
            DecimalPlaces = 0 : 4;
        }
        field(51; "FCP Dest. Amount"; Decimal)
        {
            Caption = 'FCP Destination (vFCPUFDest)';
            AutoFormatType = 1;
        }
        // IPI
        field(60; "IPI CST"; Code[2])
        {
            Caption = 'IPI CST';
        }
        field(61; "IPI Enq. Code"; Code[3])
        {
            Caption = 'IPI Framework Code (cEnq)';
        }
        field(62; "IPI Base"; Decimal)
        {
            Caption = 'IPI Base (vBC)';
            AutoFormatType = 1;
        }
        field(63; "IPI %"; Decimal)
        {
            Caption = 'IPI % (pIPI)';
            DecimalPlaces = 0 : 4;
        }
        field(64; "IPI Amount"; Decimal)
        {
            Caption = 'IPI (vIPI)';
            AutoFormatType = 1;
        }
        // PIS / COFINS
        field(70; "PIS CST"; Code[2])
        {
            Caption = 'PIS CST';
        }
        field(71; "PIS Base"; Decimal)
        {
            Caption = 'PIS Base';
            AutoFormatType = 1;
        }
        field(72; "PIS %"; Decimal)
        {
            Caption = 'PIS %';
            DecimalPlaces = 0 : 4;
        }
        field(73; "PIS Amount"; Decimal)
        {
            Caption = 'PIS';
            AutoFormatType = 1;
        }
        field(74; "COFINS CST"; Code[2])
        {
            Caption = 'COFINS CST';
        }
        field(75; "COFINS Base"; Decimal)
        {
            Caption = 'COFINS Base';
            AutoFormatType = 1;
        }
        field(76; "COFINS %"; Decimal)
        {
            Caption = 'COFINS %';
            DecimalPlaces = 0 : 4;
        }
        field(77; "COFINS Amount"; Decimal)
        {
            Caption = 'COFINS';
            AutoFormatType = 1;
        }
        // IBS / CBS (NT 2025.002)
        field(80; "IBS/CBS CST"; Code[3])
        {
            Caption = 'IBS/CBS CST';
        }
        field(81; cClassTrib; Code[6])
        {
            Caption = 'cClassTrib';
            TableRelation = "NFB cClassTrib";
        }
        field(82; "IBS/CBS Base"; Decimal)
        {
            Caption = 'IBS/CBS Base (vBC)';
            AutoFormatType = 1;
        }
        field(83; "IBS UF %"; Decimal)
        {
            Caption = 'IBS State % (pIBSUF)';
            DecimalPlaces = 0 : 4;
        }
        field(84; "IBS UF Amount"; Decimal)
        {
            Caption = 'IBS State (vIBSUF)';
            AutoFormatType = 1;
        }
        field(85; "IBS Mun. %"; Decimal)
        {
            Caption = 'IBS Municipality % (pIBSMun)';
            DecimalPlaces = 0 : 4;
        }
        field(86; "IBS Mun. Amount"; Decimal)
        {
            Caption = 'IBS Municipality (vIBSMun)';
            AutoFormatType = 1;
        }
        field(87; "CBS %"; Decimal)
        {
            Caption = 'CBS % (pCBS)';
            DecimalPlaces = 0 : 4;
        }
        field(88; "CBS Amount"; Decimal)
        {
            Caption = 'CBS (vCBS)';
            AutoFormatType = 1;
        }
        field(89; "IBS Reduction %"; Decimal)
        {
            Caption = 'IBS Rate Reduction % (pRedAliq)';
            DecimalPlaces = 0 : 4;
        }
        field(90; "CBS Reduction %"; Decimal)
        {
            Caption = 'CBS Rate Reduction % (pRedAliq)';
            DecimalPlaces = 0 : 4;
        }
        // II
        field(95; "II Base"; Decimal)
        {
            Caption = 'Import Tax Base';
            AutoFormatType = 1;
        }
        field(96; "II Customs Expenses"; Decimal)
        {
            Caption = 'Customs Expenses (vDespAdu)';
            AutoFormatType = 1;
        }
        field(97; "II Amount"; Decimal)
        {
            Caption = 'Import Tax (vII)';
            AutoFormatType = 1;
        }
        field(98; "IOF Amount"; Decimal)
        {
            Caption = 'IOF (vIOF)';
            AutoFormatType = 1;
        }
        field(100; "Additional Info"; Text[500])
        {
            Caption = 'Additional Item Info (infAdProd)';
        }
    }

    keys
    {
        key(PK; "Document No.", "Line No.") { Clustered = true; }
        key(ItemSeq; "Document No.", "Item Seq.") { }
    }

    procedure LineTotal(): Decimal
    begin
        // Contribution of the item to vNF (NT: vProd - vDesc + vST + vFCPST + vFrete + vSeg + vOutro + vII + vIPI)
        if not "Include in Total" then
            exit(0);
        exit("Products Amount" - "Discount Amount" + "ICMS ST Amount" + "FCP ST Amount" + "Freight Amount" +
             "Insurance Amount" + "Other Expenses" + "II Amount" + "IPI Amount");
    end;
}
