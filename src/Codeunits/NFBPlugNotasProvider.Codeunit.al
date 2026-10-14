codeunit 50123 "NFB PlugNotas Provider" implements "NFB IFiscal Provider"
{
    // Option 2: PlugNotas receives the JSON, generates and signs the XML and transmits it to SEFAZ.
    // Processing is asynchronous: Send stores the PlugNotas id and the result comes from QueryStatus (manually or by the job queue).

    var
        NFBPlugNotasClient: Codeunit "NFB PlugNotas Client";
        NFBProviderMgt: Codeunit "NFB Provider Mgt";
        NFBFileMgt: Codeunit "NFB File Mgt";
        NoProviderIdErr: Label 'NF-e %1 has no PlugNotas id. Send it first.', Comment = '%1 = document no.';
        NoIdReturnedErr: Label 'PlugNotas accepted the request but returned no id: %1', Comment = '%1 = response';
        UnreadableResponseErr: Label 'The PlugNotas response could not be read: %1', Comment = '%1 = response';
        ConnectionOkMsg: Label 'Connection to %1 is working. Company %2 (%3) is registered in PlugNotas.', Comment = '%1 = url, %2 = CNPJ, %3 = name';
        ConnectionFailedMsg: Label 'Connection to %1 failed. %2', Comment = '%1 = url, %2 = error';
        JsonFileNameTxt: Label '%1-plugnotas.json', Locked = true, Comment = '%1 = access key';
        AuthorizedXmlFileNameTxt: Label '%1-procNFe.xml', Locked = true, Comment = '%1 = access key';
        CancelXmlFileNameTxt: Label '%1-110111-1-procEventoNFe.xml', Locked = true, Comment = '%1 = access key';
        CorrectionXmlFileNameTxt: Label '%1-110110-%2-procEventoNFe.xml', Locked = true, Comment = '%1 = access key, %2 = sequence';
        ProcessingTxt: Label 'Processing at PlugNotas (%1).', Comment = '%1 = PlugNotas status';

    procedure Send(var NFBDocumentHeader: Record "NFB Document Header")
    var
        NFBPlugNotasPayload: Codeunit "NFB PlugNotas Payload";
        TempBlob: Codeunit "Temp Blob";
        Doc: JsonObject;
        Body: JsonArray;
        Response: JsonObject;
        BodyText: Text;
        ResponseText: Text;
        ProviderId: Text;
        HttpStatus: Integer;
    begin
        // A rejected NF-e is sent again with the same number but a new idIntegracao, which PlugNotas requires to be unique.
        NFBDocumentHeader."Provider Send Count" += 1;
        Doc := NFBPlugNotasPayload.BuildDocument(NFBDocumentHeader);
        Doc.Replace('idIntegracao', GetIntegrationId(NFBDocumentHeader));
        Body.Add(Doc);
        Body.WriteTo(BodyText);
        SaveText(NFBDocumentHeader, Enum::"NFB File Type"::JSON, BodyText, StrSubstNo(JsonFileNameTxt, NFBDocumentHeader."Access Key"), TempBlob);

        if not NFBPlugNotasClient.SendJson('POST', '/nfe', BodyText, ResponseText, HttpStatus) then begin
            NFBDocumentHeader."Status Reason" := CopyStr(NFBPlugNotasClient.GetErrorText(HttpStatus, ResponseText), 1, MaxStrLen(NFBDocumentHeader."Status Reason"));
            NFBDocumentHeader.Modify();
            Commit();
            Error('%1', NFBPlugNotasClient.GetErrorText(HttpStatus, ResponseText));
        end;
        // PlugNotas has registered the idIntegracao: keep the send count even if the response cannot be read.
        NFBDocumentHeader.Modify();
        Commit();
        if not Response.ReadFrom(ResponseText) then
            Error(UnreadableResponseErr, ResponseText);
        ProviderId := NFBPlugNotasClient.GetText(Response, 'documents[0].id');
        if ProviderId = '' then
            Error(NoIdReturnedErr, ResponseText);

        NFBDocumentHeader."Provider Id" := CopyStr(ProviderId, 1, MaxStrLen(NFBDocumentHeader."Provider Id"));
        NFBDocumentHeader."Provider Status" := 'PROCESSANDO';
        NFBDocumentHeader."Status Code" := 0;
        NFBDocumentHeader."Status Reason" := CopyStr(NFBPlugNotasClient.GetText(Response, 'message'), 1, MaxStrLen(NFBDocumentHeader."Status Reason"));
        NFBDocumentHeader.Status := NFBDocumentHeader.Status::Sent;
        NFBDocumentHeader.Modify();
        Commit();
    end;

    procedure QueryStatus(var NFBDocumentHeader: Record "NFB Document Header")
    var
        Summary: JsonObject;
        ResponseText: Text;
        ProviderStatus: Text;
        ReturnedKey: Text;
        Reason: Text;
        HttpStatus: Integer;
        StatusCode: Integer;
    begin
        if NFBDocumentHeader."Provider Id" = '' then
            Error(NoProviderIdErr, NFBDocumentHeader."No.");
        if not NFBPlugNotasClient.SendJson('GET', '/nfe/' + NFBDocumentHeader."Provider Id" + '/resumo', '', ResponseText, HttpStatus) then
            Error('%1', NFBPlugNotasClient.GetErrorText(HttpStatus, ResponseText));
        if not NFBPlugNotasClient.ReadFirstObject(ResponseText, Summary) then
            Error(UnreadableResponseErr, ResponseText);

        ProviderStatus := NormalizeStatus(NFBPlugNotasClient.GetText(Summary, 'status'));
        StatusCode := NFBPlugNotasClient.GetInteger(Summary, 'cStat');
        Reason := NFBPlugNotasClient.GetText(Summary, 'mensagem');
        NFBDocumentHeader."Provider Status" := CopyStr(ProviderStatus, 1, MaxStrLen(NFBDocumentHeader."Provider Status"));
        NFBDocumentHeader."Last Status Query" := CurrentDateTime();

        case ProviderStatus of
            'CONCLUIDO':
                begin
                    ReturnedKey := NFBPlugNotasClient.GetText(Summary, 'chave');
                    if StrLen(ReturnedKey) = 44 then
                        NFBDocumentHeader."Access Key" := CopyStr(ReturnedKey, 1, MaxStrLen(NFBDocumentHeader."Access Key"));
                    if StatusCode = 0 then
                        StatusCode := 100;
                    NFBProviderMgt.ApplyAuthorizationResult(NFBDocumentHeader, StatusCode, Reason,
                        NFBPlugNotasClient.GetText(Summary, 'protocolo'), GetDateTime(NFBPlugNotasClient.GetText(Summary, 'dataAutorizacao')));
                    Commit();
                    if NFBDocumentHeader.Status = NFBDocumentHeader.Status::Authorized then
                        DownloadAuthorizedFiles(NFBDocumentHeader);
                end;
            'REJEITADO', 'DENEGADO':
                begin
                    if (StatusCode = 0) and (ProviderStatus = 'DENEGADO') then
                        StatusCode := 302;
                    if Reason = '' then
                        Reason := NFBPlugNotasClient.GetText(Summary, 'mensagemError');
                    NFBProviderMgt.ApplyAuthorizationResult(NFBDocumentHeader, StatusCode, Reason,
                        NFBPlugNotasClient.GetText(Summary, 'protocolo'), GetDateTime(NFBPlugNotasClient.GetText(Summary, 'dataAutorizacao')));
                end;
            'CANCELADO':
                begin
                    NFBDocumentHeader.Status := NFBDocumentHeader.Status::Cancelled;
                    NFBDocumentHeader."Status Reason" := CopyStr(Reason, 1, MaxStrLen(NFBDocumentHeader."Status Reason"));
                    NFBDocumentHeader.Modify();
                end;
            else begin
                if Reason = '' then
                    Reason := StrSubstNo(ProcessingTxt, ProviderStatus);
                NFBDocumentHeader."Status Reason" := CopyStr(Reason, 1, MaxStrLen(NFBDocumentHeader."Status Reason"));
                NFBDocumentHeader.Modify();
            end;
        end;
        Commit();
    end;

    procedure Cancel(var NFBDocumentHeader: Record "NFB Document Header"; var NFBDocumentEvent: Record "NFB Document Event")
    var
        Request: JsonObject;
        Response: JsonObject;
        RequestText: Text;
        ResponseText: Text;
        HttpStatus: Integer;
    begin
        if NFBDocumentHeader."Provider Id" = '' then
            Error(NoProviderIdErr, NFBDocumentHeader."No.");
        Request.Add('justificativa', NFBDocumentEvent."Event Text");
        Request.WriteTo(RequestText);
        if not NFBPlugNotasClient.SendJson('POST', '/nfe/' + NFBDocumentHeader."Provider Id" + '/cancelamento', RequestText, ResponseText, HttpStatus) then
            Error('%1', NFBPlugNotasClient.GetErrorText(HttpStatus, ResponseText));
        if Response.ReadFrom(ResponseText) then
            NFBDocumentEvent."Provider Id" := CopyStr(FirstText(NFBPlugNotasClient.GetText(Response, 'data.protocol'), NFBPlugNotasClient.GetText(Response, 'data.protocolo')), 1, MaxStrLen(NFBDocumentEvent."Provider Id"));
        NFBDocumentEvent.Modify();
        Commit();
        QueryEventStatus(NFBDocumentHeader, NFBDocumentEvent);
    end;

    procedure CorrectionLetter(var NFBDocumentHeader: Record "NFB Document Header"; var NFBDocumentEvent: Record "NFB Document Event")
    var
        Request: JsonObject;
        Response: JsonObject;
        RequestText: Text;
        ResponseText: Text;
        HttpStatus: Integer;
    begin
        if NFBDocumentHeader."Provider Id" = '' then
            Error(NoProviderIdErr, NFBDocumentHeader."No.");
        Request.Add('correcao', NFBDocumentEvent."Event Text");
        Request.WriteTo(RequestText);
        if not NFBPlugNotasClient.SendJson('POST', '/nfe/' + NFBDocumentHeader."Provider Id" + '/cce', RequestText, ResponseText, HttpStatus) then
            Error('%1', NFBPlugNotasClient.GetErrorText(HttpStatus, ResponseText));
        if Response.ReadFrom(ResponseText) then
            NFBDocumentEvent."Provider Id" := CopyStr(NFBPlugNotasClient.GetText(Response, 'data.protocolo'), 1, MaxStrLen(NFBDocumentEvent."Provider Id"));
        NFBDocumentEvent.Modify();
        Commit();
        QueryEventStatus(NFBDocumentHeader, NFBDocumentEvent);
    end;

    procedure QueryEventStatus(var NFBDocumentHeader: Record "NFB Document Header"; var NFBDocumentEvent: Record "NFB Document Event")
    var
        Response: JsonObject;
        ResponseText: Text;
        Path: Text;
        EventStatus: Text;
        Reason: Text;
        HttpStatus: Integer;
        StatusCode: Integer;
    begin
        if NFBDocumentHeader."Provider Id" = '' then
            Error(NoProviderIdErr, NFBDocumentHeader."No.");
        case NFBDocumentEvent."Event Type" of
            NFBDocumentEvent."Event Type"::Cancellation:
                Path := '/nfe/' + NFBDocumentHeader."Provider Id" + '/cancelamento/status';
            else
                // With the protocol PlugNotas returns that specific CC-e; with the NF-e id it returns the latest one.
                if NFBDocumentEvent."Provider Id" <> '' then
                    Path := '/nfe/' + NFBDocumentEvent."Provider Id" + '/cce/status'
                else
                    Path := '/nfe/' + NFBDocumentHeader."Provider Id" + '/cce/status';
        end;
        if not NFBPlugNotasClient.SendJson('GET', Path, '', ResponseText, HttpStatus) then
            Error('%1', NFBPlugNotasClient.GetErrorText(HttpStatus, ResponseText));
        if not Response.ReadFrom(ResponseText) then
            Error(UnreadableResponseErr, ResponseText);

        EventStatus := NormalizeStatus(NFBPlugNotasClient.GetText(Response, 'data.status'));
        StatusCode := NFBPlugNotasClient.GetInteger(Response, 'data.cStat');
        Reason := NFBPlugNotasClient.GetText(Response, 'data.respostaSefaz');
        if Reason = '' then
            Reason := NFBPlugNotasClient.GetText(Response, 'data.mensagemErro');
        if Reason = '' then
            Reason := NFBPlugNotasClient.GetText(Response, 'message');

        case EventStatus of
            'CONCLUIDO':
                begin
                    if StatusCode = 0 then
                        StatusCode := 135;
                    NFBProviderMgt.ApplyEventResult(NFBDocumentHeader, NFBDocumentEvent, StatusCode, Reason,
                        NFBPlugNotasClient.GetText(Response, 'data.protocolo'), GetDateTime(NFBPlugNotasClient.GetText(Response, 'data.date')));
                    Commit();
                    DownloadEventXml(NFBDocumentHeader, NFBDocumentEvent);
                end;
            'REJEITADO', 'EXCEPTION':
                NFBProviderMgt.ApplyEventResult(NFBDocumentHeader, NFBDocumentEvent, StatusCode, Reason, '', 0DT);
            else begin
                NFBDocumentEvent."Status Reason" := CopyStr(Reason, 1, MaxStrLen(NFBDocumentEvent."Status Reason"));
                NFBDocumentEvent.Modify();
            end;
        end;
        Commit();
    end;

    procedure TestConnection(): Text
    var
        CompanyInformation: Record "Company Information";
        NFBValidation: Codeunit "NFB Validation";
        Response: JsonObject;
        ResponseText: Text;
        Cnpj: Text;
        HttpStatus: Integer;
    begin
        CompanyInformation.Get();
        Cnpj := NFBValidation.OnlyDigits(CompanyInformation."NFB CNPJ");
        if not NFBPlugNotasClient.SendJson('GET', '/empresa/' + Cnpj, '', ResponseText, HttpStatus) then
            exit(StrSubstNo(ConnectionFailedMsg, NFBPlugNotasClient.GetBaseUrl(), NFBPlugNotasClient.GetErrorText(HttpStatus, ResponseText)));
        if Response.ReadFrom(ResponseText) then;
        exit(StrSubstNo(ConnectionOkMsg, NFBPlugNotasClient.GetBaseUrl(), Cnpj, NFBPlugNotasClient.GetText(Response, 'razaoSocial')));
    end;

    local procedure DownloadAuthorizedFiles(var NFBDocumentHeader: Record "NFB Document Header")
    var
        NFBDocumentFile: Record "NFB Document File";
        TempBlob: Codeunit "Temp Blob";
    begin
        if not NFBFileMgt.FindLatestFile(NFBDocumentHeader."No.", Enum::"NFB File Type"::"Authorized XML", NFBDocumentFile) then
            if NFBPlugNotasClient.Download('/nfe/' + NFBDocumentHeader."Provider Id" + '/xml', TempBlob) then
                NFBFileMgt.SaveFile(NFBDocumentHeader, Enum::"NFB File Type"::"Authorized XML", TempBlob,
                    StrSubstNo(AuthorizedXmlFileNameTxt, NFBDocumentHeader."Access Key"), false);
        if not NFBFileMgt.FindLatestFile(NFBDocumentHeader."No.", Enum::"NFB File Type"::PDF, NFBDocumentFile) then
            if NFBPlugNotasClient.Download('/nfe/' + NFBDocumentHeader."Provider Id" + '/pdf', TempBlob) then
                NFBFileMgt.SaveFile(NFBDocumentHeader, Enum::"NFB File Type"::PDF, TempBlob, NFBProviderMgt.PdfFileName(NFBDocumentHeader), false);
        Commit();
    end;

    local procedure DownloadEventXml(NFBDocumentHeader: Record "NFB Document Header"; NFBDocumentEvent: Record "NFB Document Event")
    var
        TempBlob: Codeunit "Temp Blob";
        Path: Text;
        FileName: Text;
    begin
        if NFBDocumentEvent."Event Type" = NFBDocumentEvent."Event Type"::Cancellation then begin
            Path := '/nfe/' + NFBDocumentHeader."Provider Id" + '/cancelamento/xml';
            FileName := StrSubstNo(CancelXmlFileNameTxt, NFBDocumentHeader."Access Key");
        end else begin
            Path := '/nfe/' + NFBDocumentHeader."Provider Id" + '/cce/xml';
            FileName := StrSubstNo(CorrectionXmlFileNameTxt, NFBDocumentHeader."Access Key", NFBDocumentEvent."Sequence No.");
        end;
        if NFBPlugNotasClient.Download(Path, TempBlob) then
            NFBFileMgt.SaveFile(NFBDocumentHeader, Enum::"NFB File Type"::"Event XML", TempBlob, FileName, false);
        Commit();
    end;

    local procedure SaveText(NFBDocumentHeader: Record "NFB Document Header"; FileType: Enum "NFB File Type"; Content: Text; FileName: Text; var TempBlob: Codeunit "Temp Blob")
    var
        OutStr: OutStream;
    begin
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(Content);
        NFBFileMgt.SaveFile(NFBDocumentHeader, FileType, TempBlob, FileName, false);
    end;

    local procedure GetIntegrationId(NFBDocumentHeader: Record "NFB Document Header"): Text
    begin
        if NFBDocumentHeader."Provider Send Count" <= 1 then
            exit(NFBDocumentHeader."No.");
        exit(StrSubstNo('%1-%2', NFBDocumentHeader."No.", NFBDocumentHeader."Provider Send Count"));
    end;

    local procedure FirstText(Value: Text; Alternative: Text): Text
    begin
        if Value <> '' then
            exit(Value);
        exit(Alternative);
    end;

    local procedure NormalizeStatus(Value: Text): Text
    begin
        // The API returns CONCLUIDO without accent, but the documentation writes CONCLUÍDO.
        exit(UpperCase(Value.Trim()).Replace('Í', 'I'));
    end;

    local procedure GetDateTime(Value: Text): DateTime
    var
        Result: DateTime;
    begin
        Result := NFBProviderMgt.ParseDateTime(Value);
        if Result = 0DT then
            Result := CurrentDateTime();
        exit(Result);
    end;
}
