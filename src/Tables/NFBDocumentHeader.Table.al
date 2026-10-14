table 50109 "NFB Document Header"
{
    Caption = 'NF-e';
    DataClassification = CustomerContent;
    DrillDownPageId = "NFB Document List";
    LookupPageId = "NFB Document List";
    DataCaptionFields = "No.", "Recipient Name";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; "Source Doc. Type"; Enum "NFB Source Doc. Type")
        {
            Caption = 'Source Document Type';
            Editable = false;
        }
        field(3; "Source Doc. No."; Code[20])
        {
            Caption = 'Source Document No.';
            Editable = false;
        }
        field(4; Status; Enum "NFB Document Status")
        {
            Caption = 'Status';
            Editable = false;
        }
        field(5; "Issue Mode"; Enum "NFB Issue Mode")
        {
            Caption = 'Issue Mode';
        }
        field(6; Environment; Enum "NFB Environment")
        {
            Caption = 'Environment (tpAmb)';
        }
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        // ide
        field(10; Model; Code[2])
        {
            Caption = 'Model (mod)';
            InitValue = '55';
        }
        field(11; Series; Integer)
        {
            Caption = 'Series';
        }
        field(12; "NF No."; Integer)
        {
            Caption = 'NF-e No. (nNF)';
            Editable = false;
        }
        field(13; "Numeric Code"; Code[8])
        {
            Caption = 'Numeric Code (cNF)';
            Editable = false;
        }
        field(14; "Check Digit"; Integer)
        {
            Caption = 'Check Digit (cDV)';
            Editable = false;
        }
        field(15; "Access Key"; Code[44])
        {
            Caption = 'Access Key';
            Editable = false;
        }
        field(16; "Issue DateTime"; DateTime)
        {
            Caption = 'Issue Date/Time (dhEmi)';
        }
        field(17; "Exit DateTime"; DateTime)
        {
            Caption = 'Exit/Entry Date/Time (dhSaiEnt)';
        }
        field(18; "Operation Type"; Code[20])
        {
            Caption = 'Operation Type';
            TableRelation = "NFB Operation Type";
        }
        field(19; "Nature of Operation"; Text[60])
        {
            Caption = 'Nature of Operation (natOp)';
        }
        field(20; Direction; Enum "NFB Direction")
        {
            Caption = 'Direction (tpNF)';
        }
        field(21; "Destination Id"; Enum "NFB Destination Id")
        {
            Caption = 'Destination (idDest)';
        }
        field(22; Purpose; Enum "NFB Purpose")
        {
            Caption = 'Purpose (finNFe)';
        }
        field(23; "Final Consumer"; Boolean)
        {
            Caption = 'Final Consumer (indFinal)';
        }
        field(24; "Presence Indicator"; Enum "NFB Presence Indicator")
        {
            Caption = 'Buyer Presence (indPres)';
        }
        field(25; "Emission Type"; Integer)
        {
            Caption = 'Emission Type (tpEmis)';
            InitValue = 1;
        }
        field(26; "Taxable Event Municipality"; Code[7])
        {
            Caption = 'Taxable Event Municipality (cMunFG)';
            TableRelation = "NFB Municipality";
        }
        field(27; "Issuer UF Code"; Code[2])
        {
            Caption = 'Issuer State Code (cUF)';
        }
        // emit
        field(30; "Issuer CNPJ"; Code[14])
        {
            Caption = 'Issuer CNPJ';
        }
        field(31; "Issuer Name"; Text[60])
        {
            Caption = 'Issuer Name';
        }
        field(32; "Issuer IE"; Code[14])
        {
            Caption = 'Issuer IE';
        }
        field(33; "Issuer CRT"; Enum "NFB Tax Regime")
        {
            Caption = 'Issuer Tax Regime (CRT)';
        }
        field(34; "Issuer UF"; Code[2])
        {
            Caption = 'Issuer State (UF)';
        }
        field(35; "Issuer Location Code"; Code[10])
        {
            Caption = 'Issuer Location Code';
            TableRelation = Location;
        }
        // dest
        field(40; "Recipient Type"; Enum "NFB Person Type")
        {
            Caption = 'Recipient Type';
        }
        field(41; "Recipient CPF/CNPJ"; Code[14])
        {
            Caption = 'Recipient CPF/CNPJ';
        }
        field(42; "Recipient Foreign Id"; Code[20])
        {
            Caption = 'Recipient Foreign Id (idEstrangeiro)';
        }
        field(43; "Recipient Name"; Text[60])
        {
            Caption = 'Recipient Name';
        }
        field(44; "Recipient IE Indicator"; Enum "NFB IE Indicator")
        {
            Caption = 'Recipient IE Indicator';
            InitValue = "Non-Contributor";
        }
        field(45; "Recipient IE"; Code[14])
        {
            Caption = 'Recipient IE';
        }
        field(46; "Recipient Address"; Text[60])
        {
            Caption = 'Recipient Street';
        }
        field(47; "Recipient Address No."; Text[60])
        {
            Caption = 'Recipient Number';
        }
        field(48; "Recipient Address 2"; Text[60])
        {
            Caption = 'Recipient Complement';
        }
        field(49; "Recipient District"; Text[60])
        {
            Caption = 'Recipient District';
        }
        field(50; "Recipient Municipality Code"; Code[7])
        {
            Caption = 'Recipient Municipality (IBGE)';
            TableRelation = "NFB Municipality";
        }
        field(51; "Recipient City"; Text[60])
        {
            Caption = 'Recipient City';
        }
        field(52; "Recipient UF"; Code[2])
        {
            Caption = 'Recipient State (UF)';
        }
        field(53; "Recipient Post Code"; Code[8])
        {
            Caption = 'Recipient CEP';
        }
        field(54; "Recipient BACEN Code"; Code[4])
        {
            Caption = 'Recipient Country (BACEN)';
        }
        field(55; "Recipient Country"; Text[60])
        {
            Caption = 'Recipient Country';
        }
        field(56; "Recipient Phone"; Text[14])
        {
            Caption = 'Recipient Phone';
        }
        field(57; "Recipient E-Mail"; Text[80])
        {
            Caption = 'Recipient E-Mail';
        }
        field(58; "Recipient No."; Code[20])
        {
            Caption = 'Recipient No.';
        }
        field(59; "Recipient SUFRAMA"; Code[9])
        {
            Caption = 'Recipient SUFRAMA';
        }
        // total
        field(70; "ICMS Base"; Decimal)
        {
            Caption = 'ICMS Base (vBC)';
            AutoFormatType = 1;
        }
        field(71; "ICMS Amount"; Decimal)
        {
            Caption = 'ICMS (vICMS)';
            AutoFormatType = 1;
        }
        field(72; "FCP Amount"; Decimal)
        {
            Caption = 'FCP (vFCP)';
            AutoFormatType = 1;
        }
        field(73; "ICMS ST Base"; Decimal)
        {
            Caption = 'ICMS ST Base (vBCST)';
            AutoFormatType = 1;
        }
        field(74; "ICMS ST Amount"; Decimal)
        {
            Caption = 'ICMS ST (vST)';
            AutoFormatType = 1;
        }
        field(75; "FCP ST Amount"; Decimal)
        {
            Caption = 'FCP ST (vFCPST)';
            AutoFormatType = 1;
        }
        field(76; "DIFAL Dest. Amount"; Decimal)
        {
            Caption = 'DIFAL Destination (vICMSUFDest)';
            AutoFormatType = 1;
        }
        field(77; "FCP Dest. Amount"; Decimal)
        {
            Caption = 'FCP Destination (vFCPUFDest)';
            AutoFormatType = 1;
        }
        field(78; "Products Amount"; Decimal)
        {
            Caption = 'Products (vProd)';
            AutoFormatType = 1;
        }
        field(79; "Freight Amount"; Decimal)
        {
            Caption = 'Freight (vFrete)';
            AutoFormatType = 1;
        }
        field(80; "Insurance Amount"; Decimal)
        {
            Caption = 'Insurance (vSeg)';
            AutoFormatType = 1;
        }
        field(81; "Discount Amount"; Decimal)
        {
            Caption = 'Discount (vDesc)';
            AutoFormatType = 1;
        }
        field(82; "II Amount"; Decimal)
        {
            Caption = 'Import Tax (vII)';
            AutoFormatType = 1;
        }
        field(83; "IPI Amount"; Decimal)
        {
            Caption = 'IPI (vIPI)';
            AutoFormatType = 1;
        }
        field(84; "PIS Amount"; Decimal)
        {
            Caption = 'PIS (vPIS)';
            AutoFormatType = 1;
        }
        field(85; "COFINS Amount"; Decimal)
        {
            Caption = 'COFINS (vCOFINS)';
            AutoFormatType = 1;
        }
        field(86; "Other Expenses"; Decimal)
        {
            Caption = 'Other Expenses (vOutro)';
            AutoFormatType = 1;
        }
        field(87; "Invoice Amount"; Decimal)
        {
            Caption = 'NF-e Total (vNF)';
            AutoFormatType = 1;
        }
        field(88; "IBS/CBS Base"; Decimal)
        {
            Caption = 'IBS/CBS Base (vBCIBSCBS)';
            AutoFormatType = 1;
        }
        field(89; "IBS UF Amount"; Decimal)
        {
            Caption = 'IBS State (vIBSUF)';
            AutoFormatType = 1;
        }
        field(90; "IBS Mun. Amount"; Decimal)
        {
            Caption = 'IBS Municipality (vIBSMun)';
            AutoFormatType = 1;
        }
        field(91; "CBS Amount"; Decimal)
        {
            Caption = 'CBS (vCBS)';
            AutoFormatType = 1;
        }
        // Authorization return
        field(100; "Status Code"; Integer)
        {
            Caption = 'Status Code (cStat)';
            Editable = false;
        }
        field(101; "Status Reason"; Text[250])
        {
            Caption = 'Status Reason (xMotivo)';
            Editable = false;
        }
        field(102; "Protocol No."; Code[15])
        {
            Caption = 'Protocol No. (nProt)';
            Editable = false;
        }
        field(103; "Authorization DateTime"; DateTime)
        {
            Caption = 'Authorization Date/Time';
            Editable = false;
        }
        field(104; "Provider Id"; Text[50])
        {
            Caption = 'Provider Id';
            Editable = false;
        }
        // infAdic / exporta
        field(110; "Additional Info"; Text[2048])
        {
            Caption = 'Additional Info (infCpl)';
        }
        field(111; "Fiscal Info"; Text[2048])
        {
            Caption = 'Fiscal Info (infAdFisco)';
        }
        field(120; "Export Shipping UF"; Code[2])
        {
            Caption = 'Export Shipping State (UFSaidaPais)';
        }
        field(121; "Export Shipping Place"; Text[60])
        {
            Caption = 'Export Shipping Place (xLocExporta)';
        }
        field(130; "Validation Errors"; Integer)
        {
            Caption = 'Validation Errors';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(Source; "Source Doc. Type", "Source Doc. No.") { }
        key(Number; Model, Series, "NF No.") { }
        key(AccessKey; "Access Key") { }
        key(Status; Status, "Issue DateTime") { }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "NF No.", "Recipient Name", "Invoice Amount", Status) { }
    }

    trigger OnInsert()
    var
        NFBSetup: Record "NFB Setup";
        NoSeries: Codeunit "No. Series";
    begin
        if "No." = '' then begin
            NFBSetup.GetRecordOnce();
            NFBSetup.TestField("Document Nos.");
            "No." := NoSeries.GetNextNo(NFBSetup."Document Nos.");
        end;
    end;

    trigger OnDelete()
    var
        NFBDocumentLine: Record "NFB Document Line";
        NFBDocumentPayment: Record "NFB Document Payment";
        NFBDocumentInstallment: Record "NFB Document Installment";
        NFBDocumentReference: Record "NFB Document Reference";
        NFBDocumentTransport: Record "NFB Document Transport";
        NFBImportDeclaration: Record "NFB Import Declaration";
    begin
        // A numbered NF-e must be voided (inutilizada) instead of deleted.
        if (Status <> Status::Draft) or ("NF No." <> 0) then
            Error(CannotDeleteErr, "No.", Status);

        NFBDocumentLine.SetRange("Document No.", "No.");
        NFBDocumentLine.DeleteAll();
        NFBDocumentPayment.SetRange("Document No.", "No.");
        NFBDocumentPayment.DeleteAll();
        NFBDocumentInstallment.SetRange("Document No.", "No.");
        NFBDocumentInstallment.DeleteAll();
        NFBDocumentReference.SetRange("Document No.", "No.");
        NFBDocumentReference.DeleteAll();
        if NFBDocumentTransport.Get("No.") then
            NFBDocumentTransport.Delete();
        NFBImportDeclaration.SetRange("Table ID", Database::"NFB Document Line");
        NFBImportDeclaration.SetRange("Document No.", "No.");
        NFBImportDeclaration.DeleteAll();
    end;

    procedure TestStatusOpen()
    begin
        if not (Status in [Status::Draft, Status::Validated, Status::Rejected]) then
            Error(NotEditableErr, "No.", Status);
    end;

    var
        CannotDeleteErr: Label 'NF-e %1 cannot be deleted because its status is %2 or it already has a number. Void the number instead.', Comment = '%1 = document no., %2 = status';
        NotEditableErr: Label 'NF-e %1 cannot be changed because its status is %2.', Comment = '%1 = document no., %2 = status';
}
