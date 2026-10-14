tableextension 50205 "NFB Item" extends Item
{
    fields
    {
        field(50200; "NFB NCM"; Code[8])
        {
            Caption = 'NCM';
            DataClassification = CustomerContent;
            TableRelation = "NFB NCM";

            trigger OnValidate()
            var
                NFBNCM: Record "NFB NCM";
            begin
                if NFBNCM.Get("NFB NCM") then begin
                    if NFBNCM.CEST <> '' then
                        "NFB CEST" := NFBNCM.CEST;
                    "NFB Ex TIPI" := NFBNCM."Ex TIPI";
                end;
            end;
        }
        field(50201; "NFB CEST"; Code[7])
        {
            Caption = 'CEST';
            DataClassification = CustomerContent;
            Numeric = true;
        }
        field(50202; "NFB Origin"; Enum "NFB Goods Origin")
        {
            Caption = 'Goods Origin';
            DataClassification = CustomerContent;
        }
        field(50203; "NFB Ex TIPI"; Code[3])
        {
            Caption = 'Ex TIPI';
            DataClassification = CustomerContent;
        }
        field(50204; "NFB GTIN"; Code[14])
        {
            Caption = 'GTIN (EAN)';
            DataClassification = CustomerContent;
            Numeric = true;
        }
        field(50205; "NFB Taxable Unit"; Code[10])
        {
            Caption = 'Taxable Unit of Measure';
            DataClassification = CustomerContent;
            TableRelation = "Unit of Measure";
        }
        field(50206; "NFB Taxable Unit Factor"; Decimal)
        {
            Caption = 'Taxable Units per Base Unit';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            InitValue = 1;
            MinValue = 0;
        }
        field(50207; "NFB Tax Group"; Code[20])
        {
            Caption = 'NF-e Tax Group';
            DataClassification = CustomerContent;
        }
        field(50208; "NFB cClassTrib"; Code[6])
        {
            Caption = 'Default cClassTrib';
            DataClassification = CustomerContent;
            TableRelation = "NFB cClassTrib";
        }
    }
}
