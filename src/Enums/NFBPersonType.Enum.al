enum 50104 "NFB Person Type"
{
    Extensible = false;
    Caption = 'Person Type';

    value(0; "Legal Entity") { Caption = 'Legal Entity (CNPJ)'; }
    value(1; "Natural Person") { Caption = 'Natural Person (CPF)'; }
    value(2; Foreign) { Caption = 'Foreign'; }
}
