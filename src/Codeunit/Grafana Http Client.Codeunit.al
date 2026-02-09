namespace BradFullwood.GrafanaTelemetry;

/// <summary>
/// HTTP client for sending telemetry data to Grafana using InfluxDB line protocol.
/// Handles authentication and secure API key storage.
/// </summary>
codeunit 50100 "BJF Grafana Http Client"
{
    Access = Internal;

    var
        IsolatedStorageTok: Label 'BJF-Grafana-API-Key', Locked = true;
        ApiKeyNotSetErr: Label 'API key has not been configured.';
        EndpointNotConfiguredErr: Label 'Grafana endpoint has not been configured.';
        AuthFailedErr: Label 'Authentication failed. Check User ID and API Key.';
        HttpStatusErr: Label 'HTTP %1: %2', Locked = true, Comment = '%1 = Status Code, %2 = Error Message';
        TokenTok: Label 'Token %1', Locked = true, Comment = '%1 = API Key';

    /// <summary>
    /// Sends telemetry payload to Grafana using InfluxDB line protocol.
    /// </summary>
    /// <param name="Payload">The InfluxDB line protocol formatted payload.</param>
    /// <returns>True if the send was successful, false otherwise.</returns>
    [NonDebuggable]
    procedure SendTelemetry(Payload: Text): Boolean
    var
        TelemetrySetup: Record "BJF Telemetry Setup";
        HttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        HttpContent: HttpContent;
        HttpHeaders: HttpHeaders;
        ContentHeaders: HttpHeaders;
        AuthHeaderValue: SecretText;
    begin
        TelemetrySetup.GetInstance();

        if TelemetrySetup."Grafana Endpoint" = '' then
            Error(this.EndpointNotConfiguredErr);

        if not TelemetrySetup."API Key Set" then
            Error(this.ApiKeyNotSetErr);

        AuthHeaderValue := this.GetTokenAuthHeader();

        HttpContent.WriteFrom(Payload);
        HttpContent.GetHeaders(ContentHeaders);
        if ContentHeaders.Contains('Content-Type') then
            ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'text/plain; charset=utf-8');

        HttpRequestMessage.Method('POST');
        HttpRequestMessage.SetRequestUri(TelemetrySetup."Grafana Endpoint");
        HttpRequestMessage.Content(HttpContent);
        HttpRequestMessage.GetHeaders(HttpHeaders);
        HttpHeaders.Add('Authorization', AuthHeaderValue);

        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then
            exit(false);

        if not HttpResponseMessage.IsSuccessStatusCode() then
            exit(false);

        exit(true);
    end;

    /// <summary>
    /// Tests the connection to Grafana by sending an empty payload.
    /// </summary>
    /// <param name="ErrorMessage">Output parameter containing any error message.</param>
    /// <returns>True if the connection test was successful, false otherwise.</returns>
    [NonDebuggable]
    procedure TestConnection(var ErrorMessage: Text): Boolean
    var
        TelemetrySetup: Record "BJF Telemetry Setup";
        HttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        HttpHeaders: HttpHeaders;
        ResponseText: Text;
        AuthHeaderValue: SecretText;
    begin
        TelemetrySetup.GetInstance();

        if TelemetrySetup."Grafana Endpoint" = '' then begin
            ErrorMessage := this.EndpointNotConfiguredErr;
            exit(false);
        end;

        if not TelemetrySetup."API Key Set" then begin
            ErrorMessage := this.ApiKeyNotSetErr;
            exit(false);
        end;

        AuthHeaderValue := this.GetTokenAuthHeader();

        HttpRequestMessage.Method('POST');
        HttpRequestMessage.SetRequestUri(TelemetrySetup."Grafana Endpoint");
        HttpRequestMessage.GetHeaders(HttpHeaders);
        HttpHeaders.Add('Authorization', AuthHeaderValue);

        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then begin
            ErrorMessage := GetLastErrorText();
            exit(false);
        end;

        // InfluxDB returns 204 No Content on success
        // or 400 Bad Request if auth is correct but payload is empty/invalid
        // Both indicate successful authentication
        if HttpResponseMessage.HttpStatusCode() in [200, 204, 400] then begin
            ErrorMessage := '';
            exit(true);
        end;

        if HttpResponseMessage.HttpStatusCode() = 401 then begin
            ErrorMessage := this.AuthFailedErr;
            exit(false);
        end;

        HttpResponseMessage.Content().ReadAs(ResponseText);
        ErrorMessage := StrSubstNo(this.HttpStatusErr, HttpResponseMessage.HttpStatusCode(), ResponseText);
        exit(false);
    end;

    /// <summary>
    /// Stores the API key in IsolatedStorage.
    /// </summary>
    /// <param name="ApiKey">The API key to store.</param>
    [NonDebuggable]
    procedure SetApiKey(ApiKey: SecretText)
    var
        TelemetrySetup: Record "BJF Telemetry Setup";
    begin
        if ApiKey.IsEmpty() then begin
            if IsolatedStorage.Contains(this.IsolatedStorageTok, DataScope::Module) then
                IsolatedStorage.Delete(this.IsolatedStorageTok, DataScope::Module);

            TelemetrySetup.GetInstance();
            TelemetrySetup."API Key Set" := false;
            TelemetrySetup.Modify(false);
            exit;
        end;

        IsolatedStorage.Set(this.IsolatedStorageTok, ApiKey, DataScope::Module);

        TelemetrySetup.GetInstance();
        TelemetrySetup."API Key Set" := true;
        TelemetrySetup.Modify(false);
    end;

    /// <summary>
    /// Checks if the API key is set in IsolatedStorage.
    /// </summary>
    /// <returns>True if the API key is set, false otherwise.</returns>
    procedure HasApiKey(): Boolean
    begin
        exit(IsolatedStorage.Contains(this.IsolatedStorageTok, DataScope::Module));
    end;

    [NonDebuggable]
    local procedure GetApiKey(): SecretText
    var
        ApiKey: SecretText;
    begin
        if not IsolatedStorage.Get(this.IsolatedStorageTok, DataScope::Module, ApiKey) then
            Error(this.ApiKeyNotSetErr);
        exit(ApiKey);
    end;

    [NonDebuggable]
    local procedure GetTokenAuthHeader(): SecretText
    var
        ApiKey: SecretText;
        AuthHeader: SecretText;
    begin
        ApiKey := this.GetApiKey();
        AuthHeader := SecretStrSubstNo(this.TokenTok, ApiKey);
        exit(AuthHeader);
    end;
}
