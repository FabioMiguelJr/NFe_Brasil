tableextension 50105 "NFB Item" extends Item
{
    fields
    {
        field(50100; "NFB NCM"; Code[8])
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
        field(50101; "NFB CEST"; Code[7])
        {
            Caption = 'CEST';
            DataClassification = CustomerContent;
            Numeric = true;
        }
        field(50102; "NFB Origin"; Enum "NFB Goods Origin")
        {
            Caption = 'Goods Origin';
            DataClassification = CustomerContent;
        }
        field(50103; "NFB Ex TIPI"; Code[3])
        {
            Caption = 'Ex TIPI';
            DataClassification = CustomerContent;
        }
        field(50104; "NFB GTIN"; Code[14])
        {
            Caption = 'GTIN (EAN)';
            DataClassification = CustomerContent;
            Numeric = true;
        }
        field(50105; "NFB Taxable Unit"; Code[10])
        {
            Caption = 'Taxable Unit of Measure';
            DataClassification = CustomerContent;
            TableRelation = "Unit of Measure";
        }
        field(50106; "NFB Taxable Unit Factor"; Decimal)
        {
            Caption = 'Taxable Units per Base Unit';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            InitValue = 1;
            MinValue = 0;
        }
        field(50107; "NFB Tax Group"; Code[20])
        {
            Caption = 'NF-e Tax Group';
            DataClassification = CustomerContent;
        }
        field(50108; "NFB cClassTrib"; Code[6])
        {
            Caption = 'Default cClassTrib';
            DataClassification = CustomerContent;
            TableRelation = "NFB cClassTrib";
        }
    }
}
