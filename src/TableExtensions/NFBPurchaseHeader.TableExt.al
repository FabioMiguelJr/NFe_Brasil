tableextension 50214 "NFB Purchase Header" extends "Purchase Header"
{
    fields
    {
        field(50200; "NFB Operation Type"; Code[20])
        {
            Caption = 'NF-e Operation Type';
            DataClassification = CustomerContent;
            TableRelation = "NFB Operation Type";

            trigger OnValidate()
            var
                NFBOperationMgt: Codeunit "NFB Operation Mgt";
            begin
                NFBOperationMgt.ApplyToPurchaseHeader(Rec);
            end;
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
    }
}
