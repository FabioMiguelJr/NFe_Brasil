table 50211 "NFB Document Payment"
{
    Caption = 'NF-e Payment (detPag)';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "NFB Document Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Payment Indicator"; Option)
        {
            Caption = 'Payment Indicator (indPag)';
            OptionMembers = "Cash","Term";
            OptionCaption = '0 - Cash,1 - Term';
        }
        field(4; "Payment Type"; Code[2])
        {
            Caption = 'Payment Type (tPag)';
            Numeric = true;
        }
        field(5; Description; Text[60])
        {
            Caption = 'Description (xPag)';
        }
        field(6; Amount; Decimal)
        {
            Caption = 'Amount (vPag)';
            AutoFormatType = 1;
        }
        field(7; "Card Integration"; Option)
        {
            Caption = 'Card Integration (tpIntegra)';
            OptionMembers = " ","Integrated","Not Integrated";
            OptionCaption = ' ,1 - Integrated,2 - Not integrated';
        }
        field(8; "Card Acquirer CNPJ"; Code[14])
        {
            Caption = 'Card Acquirer CNPJ';
        }
        field(9; "Card Brand"; Code[2])
        {
            Caption = 'Card Brand (tBand)';
        }
        field(10; "Card Authorization"; Code[128])
        {
            Caption = 'Card Authorization (cAut)';
        }
        field(11; Change; Decimal)
        {
            Caption = 'Change (vTroco)';
            AutoFormatType = 1;
        }
    }

    keys
    {
        key(PK; "Document No.", "Line No.") { Clustered = true; }
    }
}
