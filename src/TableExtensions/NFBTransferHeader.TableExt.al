tableextension 50116 "NFB Transfer Header" extends "Transfer Header"
{
    fields
    {
        field(50100; "NFB Operation Type"; Code[20])
        {
            Caption = 'NF-e Operation Type';
            DataClassification = CustomerContent;
            TableRelation = "NFB Operation Type";

            trigger OnValidate()
            var
                NFBOperationMgt: Codeunit "NFB Operation Mgt";
            begin
                NFBOperationMgt.ApplyToTransferHeader(Rec);
            end;
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
    }
}
