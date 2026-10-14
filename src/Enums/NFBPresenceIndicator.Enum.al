enum 50109 "NFB Presence Indicator"
{
    Extensible = false;
    Caption = 'Buyer Presence (indPres)';

    value(0; "Not Applicable") { Caption = '0 - Not applicable'; }
    value(1; "In Person") { Caption = '1 - In person'; }
    value(2; Internet) { Caption = '2 - Internet'; }
    value(3; Telephone) { Caption = '3 - Telephone'; }
    value(4; "Home Delivery") { Caption = '4 - NFC-e home delivery'; }
    value(5; "In Person Outside") { Caption = '5 - In person, outside the establishment'; }
    value(9; Other) { Caption = '9 - Other'; }
}
