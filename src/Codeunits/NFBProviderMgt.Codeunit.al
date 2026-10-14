codeunit 50116 "NFB Provider Mgt"
{
    // Entry point of phase 3: sends the NF-e through the provider chosen in NF-e Setup (Issue Mode),
    // queries results, requests events and imports authorized XML files produced by other systems.

    var
        CannotSendErr: Label 'NF-e %1 cannot be sent because its status is %2.', Comment = '%1 = document no., %2 = status';
        NotSentErr: Label 'NF-e %1 was not sent yet (status %2).', Comment = '%1 = document no., %2 = status';
        NotAuthorizedErr: Label 'NF-e %1 must be authorized for this event. Its status is %2.', Comment = '%1 = document no., %2 = status';
        SentMsg: Label 'NF-e %1 was sent. Status: %2.', Comment = '%1 = document no., %2 = status';
        StatusMsg: Label 'NF-e %1: %2. %3', Comment = '%1 = document no., %2 = status, %3 = authorizer message';
        EventStatusMsg: Label '%1 of NF-e %2: %3. %4', Comment = '%1 = event type, %2 = document no., %3 = status, %4 = authorizer message';
        EventTextLengthErr: Label 'The text must have between 15 and %1 characters. It has %2.', Comment = '%1 = maximum, %2 = current length';
        CancelInstructionTxt: Label 'Cancellation of NF-e %1 (number %2). Write the justification (15 to 255 characters). SEFAZ accepts the cancellation up to 24 hours after the authorization.', Comment = '%1 = document no., %2 = nNF';
        CorrectionInstructionTxt: Label 'Correction letter (CC-e) of NF-e %1 (number %2). Write the correction (15 to 1000 characters). A CC-e cannot change amounts, taxes, the recipient or the issue date. A new CC-e replaces the previous ones.', Comment = '%1 = document no., %2 = nNF';
        MaxCorrectionsErr: Label 'NF-e %1 already has 20 correction letters, the SEFAZ limit.', Comment = '%1 = document no.';
        PendingCancellationErr: Label 'NF-e %1 already has a cancellation waiting for the authorizer.', Comment = '%1 = document no.';
        ImportTitleTxt: Label 'Import authorized NF-e or event XML';
        XmlFilterTxt: Label 'XML files (*.xml)|*.xml', Locked = true;
        NotNFeXmlErr: Label 'The file is not an authorized NF-e (nfeProc) nor a registered event (procEventoNFe).';
        UnsupportedEventErr: Label 'Event type %1 is not supported. Only cancellation (110111) and correction letter (110110) events can be imported.', Comment = '%1 = tpEvento';
        DocumentNotFoundErr: Label 'No NF-e with access key %1 was found.', Comment = '%1 = access key';
        ImportedNFeMsg: Label 'NF-e %1 was updated from the XML: %2 (%3 - %4).', Comment = '%1 = document no., %2 = status, %3 = cStat, %4 = xMotivo';
        ImportedEventMsg: Label 'The %1 of NF-e %2 was imported: %3 (%4 - %5).', Comment = '%1 = event type, %2 = document no., %3 = status, %4 = cStat, %5 = xMotivo';
        JobCreatedMsg: Label 'A job queue entry was created. It queries the pending NF-e and events every %1 minutes.', Comment = '%1 = minutes';
        JobExistsMsg: Label 'The job queue entry that queries the pending NF-e already exists.';
        JobDescriptionTxt: Label 'NF-e: query pending documents and events';
        PdfFileNameTxt: Label '%1-danfe.pdf', Locked = true, Comment = '%1 = access key';

    /// <summary>
    /// Returns the provider the NF-e was sent with, so a later change of the issue mode in NF-e Setup does not redirect
    /// queries and events of documents already sent.
    /// </summary>
    procedure GetProvider(NFBDocumentHeader: Record "NFB Document Header"): Interface "NFB IFiscal Provider"
    begin
        exit(NFBDocumentHeader."Issue Mode");
    end;

    procedure GetSetupProvider(): Interface "NFB IFiscal Provider"
    var
        NFBSetup: Record "NFB Setup";
    begin
        NFBSetup.Get();
        exit(NFBSetup."Issue Mode");
    end;

    /// <summary>
    /// Validates the NF-e, generates its XML and sends it through the provider of NF-e Setup.
    /// </summary>
    procedure Send(var NFBDocumentHeader: Record "NFB Document Header"; ShowMessages: Boolean)
    var
        NFBSetup: Record "NFB Setup";
        NFBFileMgt: Codeunit "NFB File Mgt";
        Provider: Interface "NFB IFiscal Provider";
    begin
        if not (NFBDocumentHeader.Status in [NFBDocumentHeader.Status::Draft, NFBDocumentHeader.Status::Validated,
            NFBDocumentHeader.Status::"XML Generated", NFBDocumentHeader.Status::Rejected])
        then
            Error(CannotSendErr, NFBDocumentHeader."No.", NFBDocumentHeader.Status);
        NFBSetup.Get();
        NFBFileMgt.GenerateXml(NFBDocumentHeader, false);
        NFBDocumentHeader."Issue Mode" := NFBSetup."Issue Mode";
        NFBDocumentHeader.Modify();
        Commit();

        Provider := GetProvider(NFBDocumentHeader);
        Provider.Send(NFBDocumentHeader);
        if ShowMessages and (NFBDocumentHeader.Status = NFBDocumentHeader.Status::Sent) then
            Message(SentMsg, NFBDocumentHeader."No.", NFBDocumentHeader.Status);
    end;

    procedure QueryStatus(var NFBDocumentHeader: Record "NFB Document Header"; ShowMessages: Boolean)
    var
        Provider: Interface "NFB IFiscal Provider";
    begin
        if not (NFBDocumentHeader.Status in [NFBDocumentHeader.Status::Sent, NFBDocumentHeader.Status::Authorized]) then
            Error(NotSentErr, NFBDocumentHeader."No.", NFBDocumentHeader.Status);
        Provider := GetProvider(NFBDocumentHeader);
        Provider.QueryStatus(NFBDocumentHeader);
        if ShowMessages then
            Message(StatusMsg, NFBDocumentHeader."No.", NFBDocumentHeader.Status, NFBDocumentHeader."Status Reason");
    end;

    procedure RequestCancellation(var NFBDocumentHeader: Record "NFB Document Header")
    var
        NFBDocumentEvent: Record "NFB Document Event";
        Provider: Interface "NFB IFiscal Provider";
        Justification: Text;
    begin
        if NFBDocumentHeader.Status <> NFBDocumentHeader.Status::Authorized then
            Error(NotAuthorizedErr, NFBDocumentHeader."No.", NFBDocumentHeader.Status);
        NFBDocumentEvent.SetRange("Document No.", NFBDocumentHeader."No.");
        NFBDocumentEvent.SetRange("Event Type", NFBDocumentEvent."Event Type"::Cancellation);
        NFBDocumentEvent.SetRange(Status, NFBDocumentEvent.Status::Pending);
        if not NFBDocumentEvent.IsEmpty() then
            Error(PendingCancellationErr, NFBDocumentHeader."No.");

        if not AskEventText(StrSubstNo(CancelInstructionTxt, NFBDocumentHeader."No.", NFBDocumentHeader."NF No."), 255, Justification) then
            exit;
        CreateEvent(NFBDocumentHeader, Enum::"NFB Event Type"::Cancellation, 1, Justification, NFBDocumentEvent);

        Provider := GetProvider(NFBDocumentHeader);
        Provider.Cancel(NFBDocumentHeader, NFBDocumentEvent);
        Message(EventStatusMsg, NFBDocumentEvent."Event Type", NFBDocumentHeader."No.", NFBDocumentEvent.Status, NFBDocumentEvent."Status Reason");
    end;

    procedure RequestCorrectionLetter(var NFBDocumentHeader: Record "NFB Document Header")
    var
        NFBDocumentEvent: Record "NFB Document Event";
        Provider: Interface "NFB IFiscal Provider";
        Correction: Text;
        Sequence: Integer;
    begin
        if NFBDocumentHeader.Status <> NFBDocumentHeader.Status::Authorized then
            Error(NotAuthorizedErr, NFBDocumentHeader."No.", NFBDocumentHeader.Status);
        Sequence := NextSequence(NFBDocumentHeader."No.", Enum::"NFB Event Type"::"Correction Letter");
        if Sequence > 20 then
            Error(MaxCorrectionsErr, NFBDocumentHeader."No.");

        if not AskEventText(StrSubstNo(CorrectionInstructionTxt, NFBDocumentHeader."No.", NFBDocumentHeader."NF No."), 1000, Correction) then
            exit;
        CreateEvent(NFBDocumentHeader, Enum::"NFB Event Type"::"Correction Letter", Sequence, Correction, NFBDocumentEvent);

        Provider := GetProvider(NFBDocumentHeader);
        Provider.CorrectionLetter(NFBDocumentHeader, NFBDocumentEvent);
        Message(EventStatusMsg, NFBDocumentEvent."Event Type", NFBDocumentHeader."No.", NFBDocumentEvent.Status, NFBDocumentEvent."Status Reason");
    end;

    procedure QueryEventStatus(var NFBDocumentEvent: Record "NFB Document Event"; ShowMessages: Boolean)
    var
        NFBDocumentHeader: Record "NFB Document Header";
        Provider: Interface "NFB IFiscal Provider";
    begin
        NFBDocumentHeader.Get(NFBDocumentEvent."Document No.");
        if NFBDocumentEvent.Status = NFBDocumentEvent.Status::Pending then begin
            Provider := GetProvider(NFBDocumentHeader);
            Provider.QueryEventStatus(NFBDocumentHeader, NFBDocumentEvent);
        end;
        if ShowMessages then
            Message(EventStatusMsg, NFBDocumentEvent."Event Type", NFBDocumentHeader."No.", NFBDocumentEvent.Status, NFBDocumentEvent."Status Reason");
    end;

    /// <summary>
    /// Queries every sent NF-e and every pending event. Used by the job queue; each document is committed on its own,
    /// so one failure does not stop the others.
    /// </summary>
    procedure QueryPending()
    var
        NFBDocumentHeader: Record "NFB Document Header";
        NFBDocumentEvent: Record "NFB Document Event";
        NFBJobQueueHandler: Codeunit "NFB Job Queue Handler";
    begin
        NFBDocumentHeader.SetRange(Status, NFBDocumentHeader.Status::Sent);
        if NFBDocumentHeader.FindSet() then
            repeat
                ClearLastError();
                NFBJobQueueHandler.SetDocument(NFBDocumentHeader."No.", 0);
                if NFBJobQueueHandler.Run() then;
                Commit();
            until NFBDocumentHeader.Next() = 0;

        NFBDocumentEvent.SetRange(Status, NFBDocumentEvent.Status::Pending);
        if NFBDocumentEvent.FindSet() then
            repeat
                ClearLastError();
                NFBJobQueueHandler.SetDocument(NFBDocumentEvent."Document No.", NFBDocumentEvent."Entry No.");
                if NFBJobQueueHandler.Run() then;
                Commit();
            until NFBDocumentEvent.Next() = 0;
    end;

    /// <summary>
    /// Applies the result of the authorization (cStat) to the NF-e: 100 and 150 authorize, the denial codes deny, anything else rejects.
    /// </summary>
    procedure ApplyAuthorizationResult(var NFBDocumentHeader: Record "NFB Document Header"; StatusCode: Integer; StatusReason: Text; ProtocolNo: Text; AuthorizationDateTime: DateTime)
    begin
        NFBDocumentHeader."Status Code" := StatusCode;
        NFBDocumentHeader."Status Reason" := CopyStr(StatusReason, 1, MaxStrLen(NFBDocumentHeader."Status Reason"));
        case true of
            IsAuthorizedCode(StatusCode):
                begin
                    NFBDocumentHeader.Status := NFBDocumentHeader.Status::Authorized;
                    NFBDocumentHeader."Protocol No." := CopyStr(ProtocolNo, 1, MaxStrLen(NFBDocumentHeader."Protocol No."));
                    NFBDocumentHeader."Authorization DateTime" := AuthorizationDateTime;
                end;
            IsDeniedCode(StatusCode):
                begin
                    NFBDocumentHeader.Status := NFBDocumentHeader.Status::Denied;
                    NFBDocumentHeader."Protocol No." := CopyStr(ProtocolNo, 1, MaxStrLen(NFBDocumentHeader."Protocol No."));
                    NFBDocumentHeader."Authorization DateTime" := AuthorizationDateTime;
                end;
            else
                NFBDocumentHeader.Status := NFBDocumentHeader.Status::Rejected;
        end;
        NFBDocumentHeader.Modify();
    end;

    procedure ApplyEventResult(var NFBDocumentHeader: Record "NFB Document Header"; var NFBDocumentEvent: Record "NFB Document Event"; StatusCode: Integer; StatusReason: Text; ProtocolNo: Text; RegisteredAt: DateTime)
    begin
        NFBDocumentEvent."Status Code" := StatusCode;
        NFBDocumentEvent."Status Reason" := CopyStr(StatusReason, 1, MaxStrLen(NFBDocumentEvent."Status Reason"));
        if IsEventRegisteredCode(StatusCode) then begin
            NFBDocumentEvent.Status := NFBDocumentEvent.Status::Registered;
            NFBDocumentEvent."Protocol No." := CopyStr(ProtocolNo, 1, MaxStrLen(NFBDocumentEvent."Protocol No."));
            NFBDocumentEvent."Registered At" := RegisteredAt;
            if NFBDocumentEvent."Event Type" = NFBDocumentEvent."Event Type"::Cancellation then begin
                NFBDocumentHeader.Status := NFBDocumentHeader.Status::Cancelled;
                NFBDocumentHeader.Modify();
            end;
        end else
            NFBDocumentEvent.Status := NFBDocumentEvent.Status::Rejected;
        NFBDocumentEvent.Modify();
    end;

    procedure IsAuthorizedCode(StatusCode: Integer): Boolean
    begin
        exit(StatusCode in [100, 150]);
    end;

    procedure IsDeniedCode(StatusCode: Integer): Boolean
    begin
        exit(StatusCode in [110, 205, 301, 302, 303]);
    end;

    procedure IsEventRegisteredCode(StatusCode: Integer): Boolean
    begin
        exit(StatusCode in [135, 136, 155]);
    end;

    procedure CreateEvent(NFBDocumentHeader: Record "NFB Document Header"; EventType: Enum "NFB Event Type"; Sequence: Integer; EventText: Text; var NFBDocumentEvent: Record "NFB Document Event")
    begin
        NFBDocumentEvent.Init();
        NFBDocumentEvent."Entry No." := 0;
        NFBDocumentEvent."Document No." := NFBDocumentHeader."No.";
        NFBDocumentEvent."Event Type" := EventType;
        NFBDocumentEvent."Sequence No." := Sequence;
        NFBDocumentEvent."Event Text" := CopyStr(EventText, 1, MaxStrLen(NFBDocumentEvent."Event Text"));
        NFBDocumentEvent."Access Key" := NFBDocumentHeader."Access Key";
        NFBDocumentEvent.Status := NFBDocumentEvent.Status::Pending;
        NFBDocumentEvent.Insert(true);
    end;

    local procedure NextSequence(DocumentNo: Code[20]; EventType: Enum "NFB Event Type"): Integer
    var
        NFBDocumentEvent: Record "NFB Document Event";
    begin
        NFBDocumentEvent.SetCurrentKey("Document No.", "Event Type", "Sequence No.");
        NFBDocumentEvent.SetRange("Document No.", DocumentNo);
        NFBDocumentEvent.SetRange("Event Type", EventType);
        NFBDocumentEvent.SetFilter(Status, '<>%1', NFBDocumentEvent.Status::Rejected);
        if NFBDocumentEvent.FindLast() then
            exit(NFBDocumentEvent."Sequence No." + 1);
        exit(1);
    end;

    local procedure AskEventText(Instruction: Text; MaxLength: Integer; var EventText: Text): Boolean
    var
        NFBEventDialog: Page "NFB Event Dialog";
        NFBXMLBuilder: Codeunit "NFB XML Builder";
    begin
        NFBEventDialog.SetInstruction(Instruction);
        if NFBEventDialog.RunModal() <> Action::OK then
            exit(false);
        EventText := NFBXMLBuilder.Clean(NFBEventDialog.GetEventText(), 1000);
        if (StrLen(EventText) < 15) or (StrLen(EventText) > MaxLength) then
            Error(EventTextLengthErr, MaxLength, StrLen(EventText));
        exit(true);
    end;

    /// <summary>
    /// Downloads the DANFE returned by the provider. When there is none, prints the DANFE of the extension.
    /// </summary>
    procedure DownloadPdf(NFBDocumentHeader: Record "NFB Document Header")
    var
        NFBDocumentFile: Record "NFB Document File";
        NFBFileMgt: Codeunit "NFB File Mgt";
    begin
        if NFBFileMgt.FindLatestFile(NFBDocumentHeader."No.", Enum::"NFB File Type"::PDF, NFBDocumentFile) then begin
            NFBFileMgt.DownloadFile(NFBDocumentFile);
            exit;
        end;
        NFBDocumentHeader.SetRecFilter();
        Report.Run(Report::"NFB DANFE", true, false, NFBDocumentHeader);
    end;

    procedure PdfFileName(NFBDocumentHeader: Record "NFB Document Header"): Text
    begin
        exit(StrSubstNo(PdfFileNameTxt, NFBDocumentHeader."Access Key"));
    end;

    procedure TestConnection()
    var
        Provider: Interface "NFB IFiscal Provider";
    begin
        Provider := GetSetupProvider();
        Message('%1', Provider.TestConnection());
    end;

    /// <summary>
    /// Imports an XML produced by another system: an authorized NF-e (nfeProc) or a registered event (procEventoNFe).
    /// The NF-e is found by its access key.
    /// </summary>
    procedure ImportAuthorizedXml()
    var
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        FromFile: Text;
    begin
        if not UploadIntoStream(ImportTitleTxt, '', XmlFilterTxt, FromFile, InStr) then
            exit;
        TempBlob.CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);
        ImportXmlBlob(TempBlob, GetFileName(FromFile), true);
    end;

    procedure ImportXmlBlob(var TempBlob: Codeunit "Temp Blob"; FileName: Text; ShowMessages: Boolean)
    var
        XmlDoc: XmlDocument;
        NsMgr: XmlNamespaceManager;
        Node: XmlNode;
        InStr: InStream;
    begin
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        if not XmlDocument.ReadFrom(InStr, XmlDoc) then
            Error(NotNFeXmlErr);
        NsMgr.NameTable(XmlDoc.NameTable());
        NsMgr.AddNamespace('n', 'http://www.portalfiscal.inf.br/nfe');

        if XmlDoc.SelectSingleNode('//n:protNFe/n:infProt', NsMgr, Node) then begin
            ImportNFeProc(Node, NsMgr, TempBlob, FileName, ShowMessages);
            exit;
        end;
        if XmlDoc.SelectSingleNode('//n:retEvento/n:infEvento', NsMgr, Node) then begin
            ImportEventProc(XmlDoc, Node, NsMgr, TempBlob, FileName, ShowMessages);
            exit;
        end;
        Error(NotNFeXmlErr);
    end;

    local procedure ImportNFeProc(InfProt: XmlNode; NsMgr: XmlNamespaceManager; var TempBlob: Codeunit "Temp Blob"; FileName: Text; ShowMessages: Boolean)
    var
        NFBDocumentHeader: Record "NFB Document Header";
        NFBFileMgt: Codeunit "NFB File Mgt";
        AccessKey: Text;
        StatusCode: Integer;
    begin
        AccessKey := GetChildText(InfProt, 'chNFe', NsMgr);
        FindByAccessKey(AccessKey, NFBDocumentHeader);
        if not Evaluate(StatusCode, GetChildText(InfProt, 'cStat', NsMgr)) then
            Error(NotNFeXmlErr);
        ApplyAuthorizationResult(NFBDocumentHeader, StatusCode, GetChildText(InfProt, 'xMotivo', NsMgr),
            GetChildText(InfProt, 'nProt', NsMgr), ParseDateTime(GetChildText(InfProt, 'dhRecbto', NsMgr)));
        if FileName = '' then
            FileName := AccessKey + '-procNFe.xml';
        NFBFileMgt.SaveFile(NFBDocumentHeader, Enum::"NFB File Type"::"Authorized XML", TempBlob, FileName, false);
        if ShowMessages then
            Message(ImportedNFeMsg, NFBDocumentHeader."No.", NFBDocumentHeader.Status, NFBDocumentHeader."Status Code", NFBDocumentHeader."Status Reason");
    end;

    local procedure ImportEventProc(XmlDoc: XmlDocument; InfEvento: XmlNode; NsMgr: XmlNamespaceManager; var TempBlob: Codeunit "Temp Blob"; FileName: Text; ShowMessages: Boolean)
    var
        NFBDocumentHeader: Record "NFB Document Header";
        NFBDocumentEvent: Record "NFB Document Event";
        NFBFileMgt: Codeunit "NFB File Mgt";
        DetNode: XmlNode;
        AccessKey: Text;
        EventText: Text;
        EventTypeCode: Integer;
        Sequence: Integer;
        StatusCode: Integer;
    begin
        AccessKey := GetChildText(InfEvento, 'chNFe', NsMgr);
        FindByAccessKey(AccessKey, NFBDocumentHeader);
        if not Evaluate(EventTypeCode, GetChildText(InfEvento, 'tpEvento', NsMgr)) then
            Error(NotNFeXmlErr);
        if not (EventTypeCode in [110110, 110111]) then
            Error(UnsupportedEventErr, EventTypeCode);
        if not Evaluate(Sequence, GetChildText(InfEvento, 'nSeqEvento', NsMgr)) then
            Sequence := 1;
        if not Evaluate(StatusCode, GetChildText(InfEvento, 'cStat', NsMgr)) then
            Error(NotNFeXmlErr);
        if XmlDoc.SelectSingleNode('//n:evento/n:infEvento/n:detEvento', NsMgr, DetNode) then begin
            EventText := GetChildText(DetNode, 'xJust', NsMgr);
            if EventText = '' then
                EventText := GetChildText(DetNode, 'xCorrecao', NsMgr);
        end;

        NFBDocumentEvent.SetCurrentKey("Document No.", "Event Type", "Sequence No.");
        NFBDocumentEvent.SetRange("Document No.", NFBDocumentHeader."No.");
        NFBDocumentEvent.SetRange("Event Type", Enum::"NFB Event Type".FromInteger(EventTypeCode));
        NFBDocumentEvent.SetRange("Sequence No.", Sequence);
        if not NFBDocumentEvent.FindLast() then
            CreateEvent(NFBDocumentHeader, Enum::"NFB Event Type".FromInteger(EventTypeCode), Sequence, EventText, NFBDocumentEvent);
        ApplyEventResult(NFBDocumentHeader, NFBDocumentEvent, StatusCode, GetChildText(InfEvento, 'xMotivo', NsMgr),
            GetChildText(InfEvento, 'nProt', NsMgr), ParseDateTime(GetChildText(InfEvento, 'dhRegEvento', NsMgr)));
        if FileName = '' then
            FileName := StrSubstNo('%1-%2-%3-procEventoNFe.xml', AccessKey, EventTypeCode, Sequence);
        NFBFileMgt.SaveFile(NFBDocumentHeader, Enum::"NFB File Type"::"Event XML", TempBlob, FileName, false);
        if ShowMessages then
            Message(ImportedEventMsg, NFBDocumentEvent."Event Type", NFBDocumentHeader."No.", NFBDocumentEvent.Status, StatusCode, NFBDocumentEvent."Status Reason");
    end;

    local procedure FindByAccessKey(AccessKey: Text; var NFBDocumentHeader: Record "NFB Document Header")
    begin
        NFBDocumentHeader.SetCurrentKey("Access Key");
        NFBDocumentHeader.SetRange("Access Key", CopyStr(AccessKey, 1, MaxStrLen(NFBDocumentHeader."Access Key")));
        if (AccessKey = '') or not NFBDocumentHeader.FindFirst() then
            Error(DocumentNotFoundErr, AccessKey);
    end;

    procedure GetChildText(Parent: XmlNode; Name: Text; NsMgr: XmlNamespaceManager): Text
    var
        Child: XmlNode;
    begin
        if Parent.SelectSingleNode('n:' + Name, NsMgr, Child) then
            exit(Child.AsXmlElement().InnerText());
        exit('');
    end;

    /// <summary>
    /// Reads an ISO 8601 date/time with offset (2026-10-14T10:15:00-03:00). Returns 0DT when the text cannot be read.
    /// </summary>
    procedure ParseDateTime(Value: Text) Result: DateTime
    begin
        if Value = '' then
            exit(0DT);
        if not Evaluate(Result, Value, 9) then
            Result := 0DT;
    end;

    local procedure GetFileName(Path: Text): Text
    var
        Position: Integer;
    begin
        Path := Path.Replace('\', '/');
        Position := Path.LastIndexOf('/');
        if Position > 0 then
            exit(CopyStr(Path, Position + 1));
        exit(Path);
    end;

    /// <summary>
    /// Creates a recurring job queue entry that runs NFB Job Queue Handler, which queries the pending NF-e and events.
    /// </summary>
    procedure CreateJobQueueEntry(MinutesBetweenRuns: Integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"NFB Job Queue Handler");
        if not JobQueueEntry.IsEmpty() then begin
            Message(JobExistsMsg);
            exit;
        end;
        if MinutesBetweenRuns <= 0 then
            MinutesBetweenRuns := 5;
        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"NFB Job Queue Handler";
        JobQueueEntry.Description := CopyStr(JobDescriptionTxt, 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry."Recurring Job" := true;
        JobQueueEntry."Run on Mondays" := true;
        JobQueueEntry."Run on Tuesdays" := true;
        JobQueueEntry."Run on Wednesdays" := true;
        JobQueueEntry."Run on Thursdays" := true;
        JobQueueEntry."Run on Fridays" := true;
        JobQueueEntry."Run on Saturdays" := true;
        JobQueueEntry."Run on Sundays" := true;
        JobQueueEntry."No. of Minutes between Runs" := MinutesBetweenRuns;
        JobQueueEntry."Maximum No. of Attempts to Run" := 3;
        JobQueueEntry."Rerun Delay (sec.)" := 60;
        Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry);
        Message(JobCreatedMsg, MinutesBetweenRuns);
    end;
}
