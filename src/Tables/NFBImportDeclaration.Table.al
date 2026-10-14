table 50215 "NFB Import Declaration"
{
    Caption = 'NF-e Import Declaration (DI)';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        field(2; "Document Type"; Integer)
        {
            Caption = 'Document Type';
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10; "Declaration No."; Code[15])
        {
            Caption = 'DI/DUIMP No. (nDI)';
        }
        field(11; "Declaration Date"; Date)
        {
            Caption = 'Declaration Date (dDI)';
        }
        field(12; "Customs Place"; Text[60])
        {
            Caption = 'Customs Clearance Place (xLocDesemb)';
        }
        field(13; "Customs UF"; Code[2])
        {
            Caption = 'Customs Clearance State (UFDesemb)';
        }
        field(14; "Customs Date"; Date)
        {
            Caption = 'Customs Clearance Date (dDesemb)';
        }
        field(15; "Transport Mode"; Integer)
        {
            Caption = 'International Transport Mode (tpViaTransp)';
            MinValue = 1;
            MaxValue = 14;
        }
        field(16; "AFRMM Amount"; Decimal)
        {
            Caption = 'AFRMM (vAFRMM)';
            AutoFormatType = 1;
        }
        field(17; "Intermediation Type"; Option)
        {
            Caption = 'Intermediation (tpIntermedio)';
            OptionMembers = " ","Own","Third Party","Order";
            OptionCaption = ' ,1 - Own account,2 - Third-party account,3 - By order';
        }
        field(18; "Exporter Code"; Code[60])
        {
            Caption = 'Exporter Code (cExportador)';
        }
        field(19; "Addition No."; Integer)
        {
            Caption = 'Addition No. (nAdicao)';
        }
        field(20; "Addition Seq."; Integer)
        {
            Caption = 'Addition Item Seq. (nSeqAdic)';
        }
        field(21; "Manufacturer Code"; Code[60])
        {
            Caption = 'Manufacturer Code (cFabricante)';
        }
        field(22; "II Base"; Decimal)
        {
            Caption = 'Import Tax Base';
            AutoFormatType = 1;
        }
        field(23; "II Amount"; Decimal)
        {
            Caption = 'Import Tax (vII)';
            AutoFormatType = 1;
        }
        field(24; "Customs Expenses"; Decimal)
        {
            Caption = 'Customs Expenses (vDespAdu)';
            AutoFormatType = 1;
        }
        field(25; "IOF Amount"; Decimal)
        {
            Caption = 'IOF (vIOF)';
            AutoFormatType = 1;
        }
    }

    keys
    {
        key(PK; "Table ID", "Document Type", "Document No.", "Line No.") { Clustered = true; }
    }
}
