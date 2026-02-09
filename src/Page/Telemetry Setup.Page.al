namespace BradFullwood.GrafanaTelemetry;

/// <summary>
/// Setup page for configuring Grafana telemetry integration.
/// </summary>
page 50100 "BJF Telemetry Setup"
{
    Caption = 'Telemetry Setup';
    PageType = Card;
    SourceTable = "BJF Telemetry Setup";
    UsageCategory = Administration;
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Telemetry Enabled"; Rec."Telemetry Enabled")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether telemetry collection and sending is enabled.';

                    trigger OnValidate()
                    var
                        TelemetryScheduler: Codeunit "BJF Telemetry Scheduler";
                    begin
                        if Rec."Telemetry Enabled" then
                            TelemetryScheduler.CreateJobQueueEntry()
                        else
                            TelemetryScheduler.RemoveJobQueueEntry();
                    end;
                }
            }
            group(GrafanaConnection)
            {
                Caption = 'Grafana Connection';

                field("Grafana Endpoint"; Rec."Grafana Endpoint")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Grafana InfluxDB push endpoint URL (e.g., https://your-grafana/api/v1/push/influx/write).';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Grafana Metrics Instance ID for authentication.';
                }
                field("API Key Set"; Rec."API Key Set")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates whether the API key has been configured in secure storage.';
                }
            }
            group(TrackingOptions)
            {
                Caption = 'Tracking Options';

                field("Track User Logins"; Rec."Track User Logins")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to track user login events.';
                }
                field("Track Extensions"; Rec."Track Extensions")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to track installed extensions.';
                }
                field("Track Errors"; Rec."Track Errors")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to track error events.';
                }
            }
            group(Schedule)
            {
                Caption = 'Schedule';

                field("Send Interval Minutes"; Rec."Send Interval Minutes")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how often telemetry data should be sent to Grafana in minutes.';
                }
                field("Last Send DateTime"; Rec."Last Send DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date and time when telemetry was last sent.';
                }
                field("Last Send Status"; Rec."Last Send Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the status of the last telemetry send operation.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetApiKey)
            {
                Caption = 'Set API Key';
                ToolTip = 'Set the Grafana Cloud Access Token for authentication.';
                ApplicationArea = All;
                Image = EncryptionKeys;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    GrafanaHttpClient: Codeunit "BJF Grafana Http Client";
                    ApiKeyDialog: Page "BJF API Key Dialog";
                    ApiKey: SecretText;
                begin
                    if ApiKeyDialog.RunModal() <> Action::OK then
                        exit;

                    ApiKey := ApiKeyDialog.GetApiKey();
                    GrafanaHttpClient.SetApiKey(ApiKey);
                    CurrPage.Update(false);
                    Message(this.ApiKeySetMsg);
                end;
            }
            action(TestConnection)
            {
                Caption = 'Test Connection';
                ToolTip = 'Test the connection to Grafana.';
                ApplicationArea = All;
                Image = TestFile;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    GrafanaHttpClient: Codeunit "BJF Grafana Http Client";
                    ErrorMessage: Text;
                begin
                    if GrafanaHttpClient.TestConnection(ErrorMessage) then
                        Message(this.ConnectionSuccessMsg)
                    else
                        Error(this.ConnectionFailedErr, ErrorMessage);
                end;
            }
            action(SendNow)
            {
                Caption = 'Send Now';
                ToolTip = 'Send pending telemetry to Grafana immediately.';
                ApplicationArea = All;
                Image = SendTo;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    TelemetryScheduler: Codeunit "BJF Telemetry Scheduler";
                begin
                    TelemetryScheduler.ProcessAndSendTelemetry();
                    CurrPage.Update(false);
                    Message(this.TelemetrySentMsg);
                end;
            }
            action(CollectAndSend)
            {
                Caption = 'Collect && Send';
                ToolTip = 'Collect current environment info and installed extensions, then send immediately. Works regardless of Telemetry Enabled setting.';
                ApplicationArea = All;
                Image = RefreshLines;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    TelemetryScheduler: Codeunit "BJF Telemetry Scheduler";
                    EntryCount: Integer;
                begin
                    EntryCount := TelemetryScheduler.ForceCollectAndSend();
                    CurrPage.Update(false);
                    Message(this.CollectAndSendMsg, EntryCount);
                end;
            }
            action(ViewLogEntries)
            {
                Caption = 'Log Entries';
                ToolTip = 'View telemetry log entries.';
                ApplicationArea = All;
                Image = Log;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = page "BJF Telemetry Log Entries";
            }
            action(DebugPayload)
            {
                Caption = 'Debug Payload';
                ToolTip = 'Full test with built payload.';
                ApplicationArea = All;
                Image = Debug;

                trigger OnAction()
                var
                    TelemetryCollector: Codeunit "BJF Telemetry Collector";
                    GrafanaHttpClient: Codeunit "BJF Grafana Http Client";
                    TelemetryLogEntry: Record "BJF Telemetry Log Entry";
                    Payload: Text;
                begin
                    TelemetryLogEntry.DeleteAll(false);

                    TelemetryCollector.ForceRecordEnvironmentInfo();
                    TelemetryCollector.ForceRecordInstalledExtensions();

                    Payload := TelemetryCollector.BuildLineProtocolPayload();
                    Message(this.BuiltPayloadMsg, StrLen(Payload));

                    ClearLastError();
                    if GrafanaHttpClient.SendTelemetry(Payload) then begin
                        TelemetryCollector.MarkEntriesAsSent(true, '');
                        Message(this.SentPayloadMsg, StrLen(Payload));
                    end else
                        Error(this.SendFailedErr, GetLastErrorText());
                end;
            }
            action(TestSend)
            {
                Caption = 'Test Send';
                ToolTip = 'Send a simple test metric via codeunit.';
                ApplicationArea = All;
                Image = TestDatabase;

                trigger OnAction()
                var
                    GrafanaHttpClient: Codeunit "BJF Grafana Http Client";
                    Payload: Text;
                begin
                    Payload := StrSubstNo(this.TestPayloadTok, 'codeunit', Format(this.GetUnixTimestampMs()));
                    if GrafanaHttpClient.SendTelemetry(Payload) then
                        Message(this.TestSendSuccessMsg)
                    else
                        Error(this.SendFailedErr, GetLastErrorText());
                end;
            }
            action(TestSendDirect)
            {
                Caption = 'Test Send Direct';
                ToolTip = 'Send a simple test metric directly (bypass codeunit).';
                ApplicationArea = All;
                Image = TestDatabase;

                trigger OnAction()
                var
                    TelemetrySetup: Record "BJF Telemetry Setup";
                    HttpClient: HttpClient;
                    HttpRequestMessage: HttpRequestMessage;
                    HttpResponseMessage: HttpResponseMessage;
                    HttpContent: HttpContent;
                    HttpHeaders: HttpHeaders;
                    ContentHeaders: HttpHeaders;
                    Payload: Text;
                    ResponseText: Text;
                    ApiKey: SecretText;
                    AuthHeader: SecretText;
                begin
                    TelemetrySetup.GetInstance();

                    if not IsolatedStorage.Get(this.IsolatedStorageTok, DataScope::Module, ApiKey) then
                        Error(this.ApiKeyNotSetErr);

                    AuthHeader := SecretStrSubstNo(this.TokenTok, ApiKey);
                    Payload := StrSubstNo(this.TestPayloadTok, 'direct', Format(this.GetUnixTimestampMs()));

                    HttpContent.WriteFrom(Payload);
                    HttpContent.GetHeaders(ContentHeaders);
                    if ContentHeaders.Contains('Content-Type') then
                        ContentHeaders.Remove('Content-Type');
                    ContentHeaders.Add('Content-Type', 'text/plain; charset=utf-8');

                    HttpRequestMessage.Method('POST');
                    HttpRequestMessage.SetRequestUri(TelemetrySetup."Grafana Endpoint");
                    HttpRequestMessage.Content(HttpContent);
                    HttpRequestMessage.GetHeaders(HttpHeaders);
                    HttpHeaders.Add('Authorization', AuthHeader);

                    if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then
                        Error(this.SendFailedErr, GetLastErrorText());

                    if HttpResponseMessage.IsSuccessStatusCode() then
                        Message(this.DirectSendSuccessMsg, HttpResponseMessage.HttpStatusCode())
                    else begin
                        HttpResponseMessage.Content().ReadAs(ResponseText);
                        Error(this.HttpStatusErr, HttpResponseMessage.HttpStatusCode(), ResponseText);
                    end;
                end;
            }
            action(DebugFirstLine)
            {
                Caption = 'Debug First Line';
                ToolTip = 'Collect and send only the first line of payload to isolate the issue.';
                ApplicationArea = All;
                Image = Troubleshoot;

                trigger OnAction()
                var
                    TelemetryCollector: Codeunit "BJF Telemetry Collector";
                    TelemetryLogEntry: Record "BJF Telemetry Log Entry";
                    TelemetrySetup: Record "BJF Telemetry Setup";
                    HttpClient: HttpClient;
                    HttpRequestMessage: HttpRequestMessage;
                    HttpResponseMessage: HttpResponseMessage;
                    HttpContent: HttpContent;
                    HttpHeaders: HttpHeaders;
                    ContentHeaders: HttpHeaders;
                    FullPayload: Text;
                    FirstLine: Text;
                    ResponseText: Text;
                    ApiKey: SecretText;
                    AuthHeader: SecretText;
                    NewLinePos: Integer;
                begin
                    TelemetrySetup.GetInstance();

                    if not IsolatedStorage.Get(this.IsolatedStorageTok, DataScope::Module, ApiKey) then
                        Error(this.ApiKeyNotSetErr);

                    TelemetryLogEntry.DeleteAll(false);
                    TelemetryCollector.ForceRecordEnvironmentInfo();
                    TelemetryCollector.ForceRecordInstalledExtensions();

                    FullPayload := TelemetryCollector.BuildLineProtocolPayload();
                    if FullPayload = '' then
                        Error(this.NoPayloadErr);

                    NewLinePos := FullPayload.IndexOf(this.GetNewLine());
                    if NewLinePos > 0 then
                        FirstLine := CopyStr(FullPayload, 1, NewLinePos - 1)
                    else
                        FirstLine := FullPayload;

                    Message(this.FirstLineDebugMsg,
                        StrLen(FullPayload), StrLen(FirstLine), CopyStr(FirstLine, 1, 500));

                    AuthHeader := SecretStrSubstNo(this.TokenTok, ApiKey);

                    HttpContent.WriteFrom(FirstLine);
                    HttpContent.GetHeaders(ContentHeaders);
                    if ContentHeaders.Contains('Content-Type') then
                        ContentHeaders.Remove('Content-Type');
                    ContentHeaders.Add('Content-Type', 'text/plain; charset=utf-8');

                    HttpRequestMessage.Method('POST');
                    HttpRequestMessage.SetRequestUri(TelemetrySetup."Grafana Endpoint");
                    HttpRequestMessage.Content(HttpContent);
                    HttpRequestMessage.GetHeaders(HttpHeaders);
                    HttpHeaders.Add('Authorization', AuthHeader);

                    ClearLastError();
                    if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then
                        Error(this.SendFailedErr, GetLastErrorText());

                    if HttpResponseMessage.IsSuccessStatusCode() then
                        Message(this.FirstLineSentMsg, HttpResponseMessage.HttpStatusCode())
                    else begin
                        HttpResponseMessage.Content().ReadAs(ResponseText);
                        Error(this.HttpStatusErr, HttpResponseMessage.HttpStatusCode(), ResponseText);
                    end;
                end;
            }
            action(DebugFullDirect)
            {
                Caption = 'Debug Full Direct';
                ToolTip = 'Collect and send full payload directly (bypass codeunit).';
                ApplicationArea = All;
                Image = Allocate;

                trigger OnAction()
                var
                    TelemetryCollector: Codeunit "BJF Telemetry Collector";
                    TelemetryLogEntry: Record "BJF Telemetry Log Entry";
                    TelemetrySetup: Record "BJF Telemetry Setup";
                    HttpClient: HttpClient;
                    HttpRequestMessage: HttpRequestMessage;
                    HttpResponseMessage: HttpResponseMessage;
                    HttpContent: HttpContent;
                    HttpHeaders: HttpHeaders;
                    ContentHeaders: HttpHeaders;
                    Payload: Text;
                    ResponseText: Text;
                    ApiKey: SecretText;
                    AuthHeader: SecretText;
                begin
                    TelemetrySetup.GetInstance();

                    if not IsolatedStorage.Get(this.IsolatedStorageTok, DataScope::Module, ApiKey) then
                        Error(this.ApiKeyNotSetErr);

                    TelemetryLogEntry.DeleteAll(false);
                    TelemetryCollector.ForceRecordEnvironmentInfo();
                    TelemetryCollector.ForceRecordInstalledExtensions();

                    Payload := TelemetryCollector.BuildLineProtocolPayload();
                    if Payload = '' then
                        Error(this.NoPayloadErr);

                    Message(this.SendingPayloadMsg, StrLen(Payload));

                    AuthHeader := SecretStrSubstNo(this.TokenTok, ApiKey);

                    HttpContent.WriteFrom(Payload);
                    HttpContent.GetHeaders(ContentHeaders);
                    if ContentHeaders.Contains('Content-Type') then
                        ContentHeaders.Remove('Content-Type');
                    ContentHeaders.Add('Content-Type', 'text/plain; charset=utf-8');

                    HttpRequestMessage.Method('POST');
                    HttpRequestMessage.SetRequestUri(TelemetrySetup."Grafana Endpoint");
                    HttpRequestMessage.Content(HttpContent);
                    HttpRequestMessage.GetHeaders(HttpHeaders);
                    HttpHeaders.Add('Authorization', AuthHeader);

                    ClearLastError();
                    if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then
                        Error(this.SendFailedErr, GetLastErrorText());

                    if HttpResponseMessage.IsSuccessStatusCode() then begin
                        TelemetryCollector.MarkEntriesAsSent(true, '');
                        Message(this.FullDirectSuccessMsg, HttpResponseMessage.HttpStatusCode());
                    end else begin
                        HttpResponseMessage.Content().ReadAs(ResponseText);
                        Error(this.HttpStatusErr, HttpResponseMessage.HttpStatusCode(), ResponseText);
                    end;
                end;
            }
            action(DebugLineByLine)
            {
                Caption = 'Debug Line By Line';
                ToolTip = 'Send payload line by line to find the problematic entry.';
                ApplicationArea = All;
                Image = Find;

                trigger OnAction()
                var
                    TelemetryLogEntry: Record "BJF Telemetry Log Entry";
                    TelemetrySetup: Record "BJF Telemetry Setup";
                    HttpClient: HttpClient;
                    HttpRequestMessage: HttpRequestMessage;
                    HttpResponseMessage: HttpResponseMessage;
                    HttpContent: HttpContent;
                    HttpHeaders: HttpHeaders;
                    ContentHeaders: HttpHeaders;
                    SingleLine: Text;
                    ApiKey: SecretText;
                    AuthHeader: SecretText;
                    SuccessCount: Integer;
                    EntryNo: Integer;
                begin
                    TelemetrySetup.GetInstance();

                    if not IsolatedStorage.Get(this.IsolatedStorageTok, DataScope::Module, ApiKey) then
                        Error(this.ApiKeyNotSetErr);

                    AuthHeader := SecretStrSubstNo(this.TokenTok, ApiKey);

                    TelemetryLogEntry.SetRange(Sent, false);
                    if not TelemetryLogEntry.FindSet() then
                        Error(this.NoUnsentEntriesErr);

                    SuccessCount := 0;

                    repeat
                        EntryNo := TelemetryLogEntry."Entry No.";
                        SingleLine := StrSubstNo(this.SingleLineTok,
                            TelemetryLogEntry."Metric Name",
                            TelemetryLogEntry.Labels,
                            Format(TelemetryLogEntry.Value, 0, 9),
                            Format(TelemetryLogEntry."Timestamp Nanoseconds"));

                        Clear(HttpClient);
                        Clear(HttpRequestMessage);
                        Clear(HttpResponseMessage);
                        Clear(HttpContent);

                        HttpContent.WriteFrom(SingleLine);
                        HttpContent.GetHeaders(ContentHeaders);
                        if ContentHeaders.Contains('Content-Type') then
                            ContentHeaders.Remove('Content-Type');
                        ContentHeaders.Add('Content-Type', 'text/plain; charset=utf-8');

                        HttpRequestMessage.Method('POST');
                        HttpRequestMessage.SetRequestUri(TelemetrySetup."Grafana Endpoint");
                        HttpRequestMessage.Content(HttpContent);
                        HttpRequestMessage.GetHeaders(HttpHeaders);
                        HttpHeaders.Add('Authorization', AuthHeader);

                        ClearLastError();
                        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then begin
                            Message(this.HttpFailedMsg,
                                EntryNo, GetLastErrorText(), CopyStr(SingleLine, 1, 500));
                            exit;
                        end;

                        if not HttpResponseMessage.IsSuccessStatusCode() then begin
                            Message(this.HttpErrorMsg,
                                EntryNo, HttpResponseMessage.HttpStatusCode(), CopyStr(SingleLine, 1, 500));
                            exit;
                        end;

                        SuccessCount += 1;
                    until TelemetryLogEntry.Next() = 0;

                    Message(this.AllEntriesSentMsg, SuccessCount);
                end;
            }
        }
    }

    local procedure GetUnixTimestampMs(): BigInteger
    var
        EpochDateTime: DateTime;
    begin
        EpochDateTime := CreateDateTime(19700101D, 0T);
        exit(CurrentDateTime() - EpochDateTime);
    end;

    local procedure GetNewLine(): Text
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        exit(TypeHelper.CRLFSeparator());
    end;

    trigger OnOpenPage()
    begin
        Rec.GetInstance();
    end;

    var
        IsolatedStorageTok: Label 'BJF-Grafana-API-Key', Locked = true;
        TokenTok: Label 'Token %1', Locked = true, Comment = '%1 = API Key';
        SingleLineTok: Label '%1,%2 value=%3 %4', Locked = true, Comment = '%1 = Metric Name, %2 = Labels, %3 = Value, %4 = Timestamp';
        TestPayloadTok: Label 'bc_test,source=%1 value=1 %2000000', Locked = true, Comment = '%1 = Source, %2 = Timestamp ms';
        ApiKeyNotSetErr: Label 'API key not set.';
        NoPayloadErr: Label 'No payload built.';
        NoUnsentEntriesErr: Label 'No unsent entries.';
        SendFailedErr: Label 'Send failed: %1', Comment = '%1 = Error message';
        HttpStatusErr: Label 'HTTP %1: %2', Comment = '%1 = Status code, %2 = Response text';
        ConnectionFailedErr: Label 'Connection test failed: %1', Comment = '%1 = Error message';
        ApiKeySetMsg: Label 'API key has been saved.';
        ConnectionSuccessMsg: Label 'Connection test successful.';
        TelemetrySentMsg: Label 'Telemetry has been sent.';
        CollectAndSendMsg: Label 'Collected and sent %1 telemetry entries.', Comment = '%1 = Entry count';
        BuiltPayloadMsg: Label 'Built payload: %1 chars.', Comment = '%1 = Char count';
        SentPayloadMsg: Label 'SUCCESS! Sent %1 chars.', Comment = '%1 = Char count';
        TestSendSuccessMsg: Label 'Test send via codeunit successful!';
        DirectSendSuccessMsg: Label 'Test send successful! HTTP %1', Comment = '%1 = Status code';
        FirstLineDebugMsg: Label 'Full payload: %1 chars\First line: %2 chars\Content: %3', Comment = '%1 = Full size, %2 = First line size, %3 = Content';
        FirstLineSentMsg: Label 'First line sent successfully! HTTP %1', Comment = '%1 = Status code';
        SendingPayloadMsg: Label 'Built payload: %1 chars. Sending directly...', Comment = '%1 = Char count';
        FullDirectSuccessMsg: Label 'SUCCESS! Full payload sent directly. HTTP %1', Comment = '%1 = Status code';
        HttpFailedMsg: Label 'FAILED at entry %1\Error: %2\Line: %3', Comment = '%1 = Entry number, %2 = Error message, %3 = Line content';
        HttpErrorMsg: Label 'HTTP ERROR at entry %1\Status: %2\Line: %3', Comment = '%1 = Entry number, %2 = Status code, %3 = Line content';
        AllEntriesSentMsg: Label 'All %1 entries sent successfully!', Comment = '%1 = Entry count';
}
