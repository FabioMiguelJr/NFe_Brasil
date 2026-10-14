codeunit 50118 "NFB SEFAZ Provider" implements "NFB IFiscal Provider"
{
    // Direct transmission to SEFAZ (option 1) is built in phase 4: XML signature, SOAP client for SVRS and response parser.

    var
        NotAvailableErr: Label 'Direct transmission to SEFAZ is not available yet. Use the PlugNotas or File Only issue mode in NF-e Setup.';

    procedure Send(var NFBDocumentHeader: Record "NFB Document Header")
    begin
        Error(NotAvailableErr);
    end;

    procedure QueryStatus(var NFBDocumentHeader: Record "NFB Document Header")
    begin
        Error(NotAvailableErr);
    end;

    procedure Cancel(var NFBDocumentHeader: Record "NFB Document Header"; var NFBDocumentEvent: Record "NFB Document Event")
    begin
        Error(NotAvailableErr);
    end;

    procedure CorrectionLetter(var NFBDocumentHeader: Record "NFB Document Header"; var NFBDocumentEvent: Record "NFB Document Event")
    begin
        Error(NotAvailableErr);
    end;

    procedure QueryEventStatus(var NFBDocumentHeader: Record "NFB Document Header"; var NFBDocumentEvent: Record "NFB Document Event")
    begin
        Error(NotAvailableErr);
    end;

    procedure TestConnection(): Text
    begin
        exit(NotAvailableErr);
    end;
}
