table 50114 "NFB Document Transport"
{
    Caption = 'NF-e Transport (transp)';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "NFB Document Header";
        }
        field(2; "Freight Mode"; Enum "NFB Freight Mode")
        {
            Caption = 'Freight Mode (modFrete)';
            InitValue = "No Freight";
        }
        field(3; "Carrier CPF/CNPJ"; Code[14])
        {
            Caption = 'Carrier CPF/CNPJ';
        }
        field(4; "Carrier Name"; Text[60])
        {
            Caption = 'Carrier Name';
        }
        field(5; "Carrier IE"; Code[14])
        {
            Caption = 'Carrier IE';
        }
        field(6; "Carrier Address"; Text[60])
        {
            Caption = 'Carrier Address';
        }
        field(7; "Carrier City"; Text[60])
        {
            Caption = 'Carrier City';
        }
        field(8; "Carrier UF"; Code[2])
        {
            Caption = 'Carrier State (UF)';
        }
        field(9; "Vehicle Plate"; Code[8])
        {
            Caption = 'Vehicle Plate';
        }
        field(10; "Vehicle UF"; Code[2])
        {
            Caption = 'Vehicle State (UF)';
        }
        field(11; "Volume Quantity"; Integer)
        {
            Caption = 'Volumes (qVol)';
        }
        field(12; "Volume Kind"; Text[60])
        {
            Caption = 'Kind (esp)';
        }
        field(13; Brand; Text[60])
        {
            Caption = 'Brand (marca)';
        }
        field(14; "Gross Weight"; Decimal)
        {
            Caption = 'Gross Weight (pesoB)';
            DecimalPlaces = 0 : 3;
        }
        field(15; "Net Weight"; Decimal)
        {
            Caption = 'Net Weight (pesoL)';
            DecimalPlaces = 0 : 3;
        }
    }

    keys
    {
        key(PK; "Document No.") { Clustered = true; }
    }
}
