table 50100 "NFB Setup"
{
    Caption = 'NF-e Setup';
    DataClassification = CustomerContent;
    DrillDownPageId = "NFB Setup";
    LookupPageId = "NFB Setup";

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; Environment; Enum "NFB Environment")
        {
            Caption = 'Environment';
            InitValue = Homologation;
        }
        field(3; "Issue Mode"; Enum "NFB Issue Mode")
        {
            Caption = 'Issue Mode';
        }
        field(4; "Layout Version"; Text[10])
        {
            Caption = 'Layout Version';
            InitValue = '4.00';
        }
        field(5; "Emission Type"; Integer)
        {
            Caption = 'Emission Type (tpEmis)';
            InitValue = 1;
            MinValue = 1;
            MaxValue = 9;
        }
        field(6; "Default Series"; Integer)
        {
            Caption = 'Default Series';
            TableRelation = "NFB Series".Series where(Model = const('55'));
        }
        field(7; "Document Nos."; Code[20])
        {
            Caption = 'Fiscal Document Nos.';
            TableRelation = "No. Series";
        }
        field(8; "Auto Create Document"; Boolean)
        {
            Caption = 'Create NF-e on Posting';
            InitValue = true;
        }
        field(9; "Exclude ICMS from PIS/COFINS"; Boolean)
        {
            Caption = 'Exclude ICMS from PIS/COFINS Base';
            InitValue = true;
        }
        field(10; "Exclude Taxes from IBS/CBS"; Boolean)
        {
            Caption = 'Exclude ICMS/PIS/COFINS from IBS/CBS Base';
            InitValue = true;
        }
        field(11; "Provider URL"; Text[250])
        {
            Caption = 'Provider URL';
        }
        field(20; "Sales Operation Type"; Code[20])
        {
            Caption = 'Default Sales Operation Type';
            TableRelation = "NFB Operation Type";
        }
        field(21; "Sales Return Operation Type"; Code[20])
        {
            Caption = 'Default Sales Return Operation Type';
            TableRelation = "NFB Operation Type";
        }
        field(22; "Purchase Operation Type"; Code[20])
        {
            Caption = 'Default Purchase Operation Type';
            TableRelation = "NFB Operation Type";
        }
        field(23; "Purch. Return Operation Type"; Code[20])
        {
            Caption = 'Default Purchase Return Operation Type';
            TableRelation = "NFB Operation Type";
        }
        field(24; "Transfer Operation Type"; Code[20])
        {
            Caption = 'Default Transfer Operation Type';
            TableRelation = "NFB Operation Type";
        }
        field(30; "Validate XSD"; Boolean)
        {
            Caption = 'Validate XML against XSD';
            ToolTip = 'Specifies whether the generated XML is checked against the SEFAZ schemas imported in NF-e XSD Schemas.';
        }
        field(31; "Include IBS/CBS Group"; Boolean)
        {
            Caption = 'Include IBS/CBS Group';
            InitValue = true;
            ToolTip = 'Specifies whether the IBSCBS and IBSCBSTot groups of NT 2025.002 are written to the XML.';
        }
        field(32; "Software Version"; Text[20])
        {
            Caption = 'Software Version (verProc)';
            InitValue = 'NFB 1.0';
        }
        field(33; "Resp. Tech. CNPJ"; Code[14])
        {
            Caption = 'Technical Responsible CNPJ';
        }
        field(34; "Resp. Tech. Contact"; Text[60])
        {
            Caption = 'Technical Responsible Contact';
        }
        field(35; "Resp. Tech. E-Mail"; Text[60])
        {
            Caption = 'Technical Responsible E-Mail';
        }
        field(36; "Resp. Tech. Phone"; Text[14])
        {
            Caption = 'Technical Responsible Phone';
        }
        field(37; "UTC Offset"; Text[6])
        {
            Caption = 'UTC Offset';
            InitValue = '-03:00';
            ToolTip = 'Specifies the time zone offset written in dhEmi and dhSaiEnt. Brasília time is -03:00.';
        }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }

    procedure GetRecordOnce()
    begin
        if RecordRetrieved then
            exit;
        if not Get() then begin
            Init();
            Insert();
        end;
        RecordRetrieved := true;
    end;

    var
        RecordRetrieved: Boolean;
}
