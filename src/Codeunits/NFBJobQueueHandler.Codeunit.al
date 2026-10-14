codeunit 50119 "NFB Job Queue Handler"
{
    // Run by the job queue with no parameters: queries all pending NF-e and events.
    // Run by NFB Provider Mgt with SetDocument: queries one NF-e or one event, so a failure is isolated.

    trigger OnRun()
    var
        NFBDocumentHeader: Record "NFB Document Header";
        NFBDocumentEvent: Record "NFB Document Event";
        NFBProviderMgt: Codeunit "NFB Provider Mgt";
    begin
        if DocumentNo = '' then begin
            NFBProviderMgt.QueryPending();
            exit;
        end;
        if EventEntryNo <> 0 then begin
            NFBDocumentEvent.Get(EventEntryNo);
            NFBProviderMgt.QueryEventStatus(NFBDocumentEvent, false);
            exit;
        end;
        NFBDocumentHeader.Get(DocumentNo);
        NFBProviderMgt.QueryStatus(NFBDocumentHeader, false);
    end;

    var
        DocumentNo: Code[20];
        EventEntryNo: Integer;

    procedure SetDocument(NewDocumentNo: Code[20]; NewEventEntryNo: Integer)
    begin
        DocumentNo := NewDocumentNo;
        EventEntryNo := NewEventEntryNo;
    end;
}
