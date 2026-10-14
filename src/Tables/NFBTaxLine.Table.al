table 50116 "NFB Tax Line"
{
    Caption = 'NF-e Tax Line';
    DataClassification = CustomerContent;
    DrillDownPageId = "NFB Tax Lines";
    LookupPageId = "NFB Tax Lines";

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
        field(5; "Tax Type"; Enum "NFB Tax Type")
        {
            Caption = 'Tax Type';
        }
        field(10; CST; Code[3])
        {
            Caption = 'CST';
        }
        field(11; "Base Amount"; Decimal)
        {
            Caption = 'Base Amount';
            AutoFormatType = 1;
        }
        field(12; "Rate %"; Decimal)
        {
            Caption = 'Rate %';
            DecimalPlaces = 0 : 4;
        }
        field(13; "Base Reduction %"; Decimal)
        {
            Caption = 'Base/Rate Reduction %';
            DecimalPlaces = 0 : 4;
        }
        field(14; "MVA %"; Decimal)
        {
            Caption = 'MVA %';
            DecimalPlaces = 0 : 4;
        }
        field(15; "Secondary Rate %"; Decimal)
        {
            Caption = 'Secondary Rate % (interstate rate for DIFAL)';
            DecimalPlaces = 0 : 4;
        }
        field(16; Amount; Decimal)
        {
            Caption = 'Amount';
            AutoFormatType = 1;
        }
        field(17; "Classification Code"; Code[6])
        {
            Caption = 'cClassTrib / cEnq';
        }
        field(18; "Tax Rule Code"; Code[20])
        {
            Caption = 'Tax Rule Code';
            TableRelation = "NFB Tax Rule";
        }
    }

    keys
    {
        key(PK; "Table ID", "Document Type", "Document No.", "Line No.", "Tax Type") { Clustered = true; SumIndexFields = Amount; }
    }

    procedure CopyToDocument(FromTableID: Integer; FromDocType: Integer; FromDocNo: Code[20]; FromLineNo: Integer; ToTableID: Integer; ToDocType: Integer; ToDocNo: Code[20]; ToLineNo: Integer)
    var
        FromTaxLine: Record "NFB Tax Line";
        ToTaxLine: Record "NFB Tax Line";
    begin
        FromTaxLine.SetRange("Table ID", FromTableID);
        FromTaxLine.SetRange("Document Type", FromDocType);
        FromTaxLine.SetRange("Document No.", FromDocNo);
        FromTaxLine.SetRange("Line No.", FromLineNo);
        if FromTaxLine.FindSet() then
            repeat
                ToTaxLine := FromTaxLine;
                ToTaxLine."Table ID" := ToTableID;
                ToTaxLine."Document Type" := ToDocType;
                ToTaxLine."Document No." := ToDocNo;
                ToTaxLine."Line No." := ToLineNo;
                if not ToTaxLine.Insert() then
                    ToTaxLine.Modify();
            until FromTaxLine.Next() = 0;
    end;

    procedure DeleteForDocument(TableID: Integer; DocType: Integer; DocNo: Code[20])
    var
        TaxLine: Record "NFB Tax Line";
    begin
        TaxLine.SetRange("Table ID", TableID);
        TaxLine.SetRange("Document Type", DocType);
        TaxLine.SetRange("Document No.", DocNo);
        TaxLine.DeleteAll();
    end;
}
