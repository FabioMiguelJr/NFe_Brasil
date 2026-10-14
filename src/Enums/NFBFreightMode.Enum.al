enum 50110 "NFB Freight Mode"
{
    Extensible = false;
    Caption = 'Freight Mode (modFrete)';

    value(0; "Issuer CIF") { Caption = '0 - Paid by issuer (CIF)'; }
    value(1; "Recipient FOB") { Caption = '1 - Paid by recipient (FOB)'; }
    value(2; "Third Party") { Caption = '2 - Paid by third party'; }
    value(3; "Own Issuer") { Caption = '3 - Own transport, issuer'; }
    value(4; "Own Recipient") { Caption = '4 - Own transport, recipient'; }
    value(9; "No Freight") { Caption = '9 - No freight'; }
}
