interface "NFB IFiscal Provider"
{
    /// <summary>
    /// Sends the NF-e for authorization. The XML (and, for providers that need it, the JSON) is already generated when this is called.
    /// </summary>
    procedure Send(var NFBDocumentHeader: Record "NFB Document Header");

    /// <summary>
    /// Asks the authorizer for the result of a sent NF-e and updates its status, protocol and files.
    /// </summary>
    procedure QueryStatus(var NFBDocumentHeader: Record "NFB Document Header");

    /// <summary>
    /// Requests the cancellation event (110111) of an authorized NF-e.
    /// </summary>
    procedure Cancel(var NFBDocumentHeader: Record "NFB Document Header"; var NFBDocumentEvent: Record "NFB Document Event");

    /// <summary>
    /// Requests a correction letter event (CC-e, 110110) of an authorized NF-e.
    /// </summary>
    procedure CorrectionLetter(var NFBDocumentHeader: Record "NFB Document Header"; var NFBDocumentEvent: Record "NFB Document Event");

    /// <summary>
    /// Asks the authorizer for the result of a pending event and updates it.
    /// </summary>
    procedure QueryEventStatus(var NFBDocumentHeader: Record "NFB Document Header"; var NFBDocumentEvent: Record "NFB Document Event");

    /// <summary>
    /// Checks that the authorizer can be reached with the current setup. Returns a message for the user.
    /// </summary>
    procedure TestConnection(): Text;
}
