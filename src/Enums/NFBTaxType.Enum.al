enum 50111 "NFB Tax Type"
{
    Extensible = false;
    Caption = 'Tax Type';

    value(0; " ") { Caption = ' '; }
    value(1; ICMS) { Caption = 'ICMS'; }
    value(2; FCP) { Caption = 'FCP'; }
    value(3; "ICMS ST") { Caption = 'ICMS ST'; }
    value(4; "FCP ST") { Caption = 'FCP ST'; }
    value(5; DIFAL) { Caption = 'ICMS DIFAL'; }
    value(6; "FCP Dest.") { Caption = 'FCP Destination'; }
    value(7; IPI) { Caption = 'IPI'; }
    value(8; PIS) { Caption = 'PIS'; }
    value(9; COFINS) { Caption = 'COFINS'; }
    value(10; "IBS UF") { Caption = 'IBS UF'; }
    value(11; "IBS Mun.") { Caption = 'IBS Municipality'; }
    value(12; CBS) { Caption = 'CBS'; }
    value(13; II) { Caption = 'Import Tax (II)'; }
}
