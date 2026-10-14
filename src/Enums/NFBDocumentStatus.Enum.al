enum 50102 "NFB Document Status"
{
    Extensible = false;
    Caption = 'NF-e Status';

    value(0; Draft) { Caption = 'Draft'; }
    value(1; Validated) { Caption = 'Validated'; }
    value(2; "XML Generated") { Caption = 'XML Generated'; }
    value(3; Signed) { Caption = 'Signed'; }
    value(4; Sent) { Caption = 'Sent'; }
    value(5; Authorized) { Caption = 'Authorized'; }
    value(6; Rejected) { Caption = 'Rejected'; }
    value(7; Denied) { Caption = 'Denied'; }
    value(8; Cancelled) { Caption = 'Cancelled'; }
    value(9; Voided) { Caption = 'Voided'; }
}
