codeunit 50122 "NFB PlugNotas Client"
{
    // REST client for the TecnoSpeed PlugNotas API. Authentication by the x-api-key header.
    // Sandbox: https://api.sandbox.plugnotas.com.br (simulated responses, public test key).
    // Homologation and production: https://api.plugnotas.com.br. The SEFAZ environment is chosen by config.producao
    // in the JSON and by the company registered in PlugNotas.

    var
        SandboxUrlTxt: Label 'https://api.sandbox.plugnotas.com.br', Locked = true;
        ProductionUrlTxt: Label 'https://api.plugnotas.com.br', Locked = true;
        PublicSandboxKeyTxt: Label '2da392a6-79d2-4304-a8b7-959572c7e44d', Locked = true;
        ApiKeyStorageTxt: Label 'NFB-PlugNotas-ApiKey', Locked = true;
        NoApiKeyErr: Label 'The PlugNotas API key is missing. Enter it in NF-e Setup.';
        ConnectionErr: Label 'PlugNotas could not be reached (%1 %2). Check that the Business Central server has outbound internet access to %3.', Comment = '%1 = method, %2 = url, %3 = host';
        HttpErr: Label 'PlugNotas returned HTTP %1: %2', Comment = '%1 = status code, %2 = message';

    procedure GetBaseUrl(): Text
    var
        NFBSetup: Record "NFB Setup";
    begin
        NFBSetup.Get();
        if NFBSetup."Provider URL" <> '' then
            exit(NFBSetup."Provider URL".TrimEnd('/'));
        if NFBSetup."Use PlugNotas Sandbox" then
            exit(SandboxUrlTxt);
        exit(ProductionUrlTxt);
    end;

    procedure SetApiKey(NewKey: Text)
    begin
        if NewKey = '' then begin
            if IsolatedStorage.Contains(ApiKeyStorageTxt, DataScope::Company) then
                IsolatedStorage.Delete(ApiKeyStorageTxt, DataScope::Company);
            exit;
        end;
        IsolatedStorage.Set(ApiKeyStorageTxt, NewKey, DataScope::Company);
    end;

    procedure HasApiKey(): Boolean
    begin
        exit(IsolatedStorage.Contains(ApiKeyStorageTxt, DataScope::Company));
    end;

    local procedure GetApiKey() ApiKey: SecretText
    var
        NFBSetup: Record "NFB Setup";
    begin
        if IsolatedStorage.Get(ApiKeyStorageTxt, DataScope::Company, ApiKey) then
            exit(ApiKey);
        NFBSetup.Get();
        if NFBSetup."Use PlugNotas Sandbox" and (NFBSetup."Provider URL" = '') then
            exit(PublicSandboxKeyTxt);
        Error(NoApiKeyErr);
    end;

    /// <summary>
    /// Sends a JSON request. Returns true for HTTP 2xx. The response body is returned in ResponseText either way.
    /// </summary>
    procedure SendJson(Method: Text; Path: Text; Body: Text; var ResponseText: Text; var HttpStatus: Integer): Boolean
    var
        Response: HttpResponseMessage;
    begin
        SendRequest(Method, Path, Body, Response);
        HttpStatus := Response.HttpStatusCode();
        Response.Content().ReadAs(ResponseText);
        exit(Response.IsSuccessStatusCode());
    end;

    /// <summary>
    /// Downloads a file (XML or PDF) into TempBlob. Returns false when PlugNotas does not have it.
    /// </summary>
    procedure Download(Path: Text; var TempBlob: Codeunit "Temp Blob"): Boolean
    var
        Response: HttpResponseMessage;
        InStr: InStream;
        OutStr: OutStream;
    begin
        SendRequest('GET', Path, '', Response);
        if not Response.IsSuccessStatusCode() then
            exit(false);
        Response.Content().ReadAs(InStr);
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);
        exit(TempBlob.Length() > 0);
    end;

    local procedure SendRequest(Method: Text; Path: Text; Body: Text; var Response: HttpResponseMessage)
    var
        Client: HttpClient;
        Request: HttpRequestMessage;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        RequestHeaders: HttpHeaders;
        Url: Text;
    begin
        Url := GetBaseUrl() + Path;
        Request.Method(Method);
        Request.SetRequestUri(Url);
        Request.GetHeaders(RequestHeaders);
        RequestHeaders.Add('x-api-key', GetApiKey());
        RequestHeaders.Add('Accept', '*/*');
        if Body <> '' then begin
            Content.WriteFrom(Body);
            Content.GetHeaders(ContentHeaders);
            if ContentHeaders.Contains('Content-Type') then
                ContentHeaders.Remove('Content-Type');
            ContentHeaders.Add('Content-Type', 'application/json');
            Request.Content(Content);
        end;
        Client.Timeout(60000);
        if not Client.Send(Request, Response) then
            Error(ConnectionErr, Method, Url, GetBaseUrl());
    end;

    /// <summary>
    /// Builds a readable message from a PlugNotas error body: {"error":{"message":"...","data":{"fields":{...}}}}.
    /// </summary>
    procedure GetErrorText(HttpStatus: Integer; ResponseText: Text): Text
    var
        Body: JsonObject;
        Token: JsonToken;
        Fields: JsonObject;
        FieldKey: Text;
        ErrorMessage: Text;
        Details: Text;
        TokenText: Text;
    begin
        if Body.ReadFrom(ResponseText) then begin
            ErrorMessage := GetText(Body, 'error.message');
            if ErrorMessage = '' then
                ErrorMessage := GetText(Body, 'message');
            if Body.SelectToken('error.data.fields', Token) and Token.IsObject() then begin
                Fields := Token.AsObject();
                foreach FieldKey in Fields.Keys() do begin
                    Fields.Get(FieldKey, Token);
                    if Token.IsValue() then
                        TokenText := Token.AsValue().AsText()
                    else
                        Token.WriteTo(TokenText);
                    Details += ' | ' + FieldKey + ': ' + TokenText;
                end;
            end;
        end;
        if ErrorMessage = '' then
            ErrorMessage := CopyStr(ResponseText, 1, 1000);
        exit(StrSubstNo(HttpErr, HttpStatus, ErrorMessage + Details));
    end;

    /// <summary>
    /// Reads a value by path (for example data.status). Returns an empty text when it is missing or null.
    /// </summary>
    procedure GetText(Obj: JsonObject; Path: Text): Text
    var
        Token: JsonToken;
    begin
        if not Obj.SelectToken(Path, Token) then
            exit('');
        if not Token.IsValue() then
            exit('');
        if Token.AsValue().IsNull() or Token.AsValue().IsUndefined() then
            exit('');
        exit(Token.AsValue().AsText());
    end;

    procedure GetInteger(Obj: JsonObject; Path: Text): Integer
    var
        Result: Integer;
    begin
        if Evaluate(Result, GetText(Obj, Path)) then
            exit(Result);
        exit(0);
    end;

    /// <summary>
    /// Reads a response that may be an object or an array with one object (the resumo route returns an array).
    /// </summary>
    procedure ReadFirstObject(ResponseText: Text; var Obj: JsonObject): Boolean
    var
        Arr: JsonArray;
        Token: JsonToken;
    begin
        if Obj.ReadFrom(ResponseText) then
            exit(true);
        if not Arr.ReadFrom(ResponseText) then
            exit(false);
        if Arr.Count() = 0 then
            exit(false);
        Arr.Get(0, Token);
        if not Token.IsObject() then
            exit(false);
        Obj := Token.AsObject();
        exit(true);
    end;
}
