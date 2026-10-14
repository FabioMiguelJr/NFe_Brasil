tableextension 50120 "NFB Purch. Cr. Memo Hdr." extends "Purch. Cr. Memo Hdr."
{
    fields
    {
        field(50100; "NFB Operation Type"; Code[20])
        {
            Caption = 'NF-e Operation Type';
            DataClassification = CustomerContent;
            TableRelation = "NFB Operation Type";
        }
        field(50101; "NFB Nature of Operation"; Text[60])
        {
            Caption = 'Nature of Operation (natOp)';
            DataClassification = CustomerContent;
        }
        field(50102; "NFB Purpose"; Enum "NFB Purpose")
        {
            Caption = 'NF-e Purpose (finNFe)';
            DataClassification = CustomerContent;
            InitValue = Normal;
        }
        field(50103; "NFB Presence Indicator"; Enum "NFB Presence Indicator")
        {
            Caption = 'Buyer Presence (indPres)';
            DataClassification = CustomerContent;
            InitValue = Other;
        }
        field(50104; "NFB Freight Mode"; Enum "NFB Freight Mode")
        {
            Caption = 'Freight Mode (modFrete)';
            DataClassification = CustomerContent;
            InitValue = "No Freight";
        }
        field(50105; "NFB Final Consumer"; Boolean)
        {
            Caption = 'Final Consumer';
            DataClassification = CustomerContent;
        }
        field(50106; "NFB Referenced Key"; Code[44])
        {
            Caption = 'Referenced NF-e Access Key';
            DataClassification = CustomerContent;
            Numeric = true;
        }
        field(50107; "NFB Additional Info"; Text[250])
        {
            Caption = 'NF-e Additional Info';
            DataClassification = CustomerContent;
        }
        field(50120; "NFB Document No."; Code[20])
        {
            Caption = 'NF-e Document No.';
            FieldClass = FlowField;
            CalcFormula = lookup("NFB Document Header"."No." where("Source Doc. Type" = const("Purchase Cr. Memo"), "Source Doc. No." = field("No.")));
            Editable = false;
        }
        field(50121; "NFB Status"; Enum "NFB Document Status")
        {
            Caption = 'NF-e Status';
            FieldClass = FlowField;
            CalcFormula = lookup("NFB Document Header".Status where("Source Doc. Type" = const("Purchase Cr. Memo"), "Source Doc. No." = field("No.")));
            Editable = false;
        }
        field(50122; "NFB Access Key"; Code[44])
        {
            Caption = 'NF-e Access Key';
            FieldClass = FlowField;
            CalcFormula = lookup("NFB Document Header"."Access Key" where("Source Doc. Type" = const("Purchase Cr. Memo"), "Source Doc. No." = field("No.")));
            Editable = false;
        }
    }
}
