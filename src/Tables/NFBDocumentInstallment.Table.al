table 50112 "NFB Document Installment"
{
    Caption = 'NF-e Installment (dup)';
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
        field(3; "Installment No."; Code[3])
        {
            Caption = 'Installment No. (nDup)';
        }
        field(4; "Due Date"; Date)
        {
            Caption = 'Due Date (dVenc)';
        }
        field(5; Amount; Decimal)
        {
            Caption = 'Amount (vDup)';
            AutoFormatType = 1;
        }
    }

    keys
    {
        key(PK; "Document No.", "Line No.") { Clustered = true; }
    }
}
