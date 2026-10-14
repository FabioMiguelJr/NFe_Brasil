enum 50101 "NFB Issue Mode" implements "NFB IFiscal Provider"
{
    Extensible = true;
    Caption = 'NF-e Issue Mode';
    DefaultImplementation = "NFB IFiscal Provider" = "NFB File Provider";

    value(0; "File Only")
    {
        Caption = 'File Only';
        Implementation = "NFB IFiscal Provider" = "NFB File Provider";
    }
    value(1; "SEFAZ Direct")
    {
        Caption = 'SEFAZ Direct';
        Implementation = "NFB IFiscal Provider" = "NFB SEFAZ Provider";
    }
    value(2; PlugNotas)
    {
        Caption = 'PlugNotas';
        Implementation = "NFB IFiscal Provider" = "NFB PlugNotas Provider";
    }
}
