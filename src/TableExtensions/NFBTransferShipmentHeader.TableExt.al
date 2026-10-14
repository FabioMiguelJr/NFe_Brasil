tableextension 50218 "NFB Transfer Shipment Header" extends "Transfer Shipment Header"
{
    fields
    {
        field(50200; "NFB Operation Type"; Code[20])
        {
            Caption = 'NF-e Operation Type';
            DataClassification = CustomerContent;
            TableRelation = "NFB Operation Type";
        }
        field(50201; "NFB Nature of Operation"; Text[60])
        {
            Caption = 'Nature of Operation (natOp)';
            DataClassification = CustomerContent;
        }
        field(50202; "NFB Purpose"; Enum "NFB Purpose")
        {
            Caption = 'NF-e Purpose (finNFe)';
            DataClassification = CustomerContent;
            InitValue = Normal;
        }
        field(50203; "NFB Presence Indicator"; Enum "NFB Presence Indicator")
        {
            Caption = 'Buyer Presence (indPres)';
            DataClassification = CustomerContent;
            InitValue = Other;
        }
        field(50204; "NFB Freight Mode"; Enum "NFB Freight Mode")
        {
            Caption = 'Freight Mode (modFrete)';
            DataClassification = CustomerContent;
            InitValue = "No Freight";
        }
        field(50205; "NFB Final Consumer"; Boolean)
        {
            Caption = 'Final Consumer';
            DataClassification = CustomerContent;
        }
        field(50206; "NFB Referenced Key"; Code[44])
        {
            Caption = 'Referenced NF-e Access Key';
            DataClassification = CustomerContent;
            Numeric = true;
        }
        field(50207; "NFB Additional Info"; Text[250])
        {
            Caption = 'NF-e Additional Info';
            DataClassification = CustomerContent;
        }
        field(50220; "NFB Document No."; Code[20])
        {
            Caption = 'NF-e Document No.';
            FieldClass = FlowField;
            CalcFormula = lookup("NFB Document Header"."No." where("Source Doc. Type" = const("Transfer Shipment"), "Source Doc. No." = field("No.")));
            Editable = false;
        }
        field(50221; "NFB Status"; Enum "NFB Document Status")
        {
            Caption = 'NF-e Status';
            FieldClass = FlowField;
            CalcFormula = lookup("NFB Document Header".Status where("Source Doc. Type" = const("Transfer Shipment"), "Source Doc. No." = field("No.")));
            Editable = false;
        }
        field(50222; "NFB Access Key"; Code[44])
        {
            Caption = 'NF-e Access Key';
            FieldClass = FlowField;
            CalcFormula = lookup("NFB Document Header"."Access Key" where("Source Doc. Type" = const("Transfer Shipment"), "Source Doc. No." = field("No.")));
            Editable = false;
        }
    }
}
