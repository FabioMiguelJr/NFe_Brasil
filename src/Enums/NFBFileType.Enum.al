enum 50114 "NFB File Type"
{
    Extensible = true;
    Caption = 'NF-e File Type';

    value(0; XML) { Caption = 'XML (unsigned)'; }
    value(1; "Signed XML") { Caption = 'Signed XML'; }
    value(2; "Authorized XML") { Caption = 'Authorized XML (nfeProc)'; }
    value(3; JSON) { Caption = 'JSON'; }
    value(4; PDF) { Caption = 'PDF (DANFE)'; }
    value(5; "Event XML") { Caption = 'Event XML'; }
}
