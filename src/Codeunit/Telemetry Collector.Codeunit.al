namespace BradFullwood.GrafanaTelemetry;

/// <summary>
/// Collects telemetry data and creates log entries for sending to Grafana.
/// Handles user logins, installed extensions, environment info, and errors.
/// </summary>
codeunit 50101 "BJF Telemetry Collector"
{
    Access = Internal;

    var
        LineProtocolTok: Label '%1,%2 value=%3 %4', Locked = true, Comment = '%1 = Metric Name, %2 = Labels, %3 = Value, %4 = Timestamp';
        LabelPairTok: Label '%1=%2', Locked = true, Comment = '%1 = Key, %2 = Value';
        LabelSeparatorTok: Label ',%1=%2', Locked = true, Comment = '%1 = Key, %2 = Value';
        UnknownUserTxt: Label 'Unknown', Locked = true;

    /// <summary>
    /// Records a user login event.
    /// </summary>
    /// <param name="UserSecurityId">The security ID of the user who logged in.</param>
    procedure RecordUserLogin(UserSecurityId: Guid)
    var
        TelemetrySetup: Record "BJF Telemetry Setup";
        User: Record User;
        EnvironmentInformation: Codeunit "Environment Information";
        Labels: Text;
        UserName: Text;
    begin
        TelemetrySetup.GetInstance();
        if not TelemetrySetup."Telemetry Enabled" then
            exit;
        if not TelemetrySetup."Track User Logins" then
            exit;

        UserName := this.UnknownUserTxt;
        if User.GetBySystemId(UserSecurityId) then
            UserName := User."User Name";

        Labels := this.BuildLabels(
            'environment', this.GetEnvironmentName(),
            'tenant_id', this.GetTenantId(),
            'company', this.GetCompanyName(),
            'user', UserName,
            'is_saas', Format(EnvironmentInformation.IsSaaS(), 0, 9),
            'is_production', Format(EnvironmentInformation.IsProduction(), 0, 9),
            'app_version', this.GetApplicationVersion()
        );

        this.CreateLogEntry(
            Enum::"BJF Telemetry Type"::UserLogin,
            'bc_user_login',
            Labels,
            1
        );
    end;

    /// <summary>
    /// Records all installed extensions as telemetry events.
    /// </summary>
    procedure RecordInstalledExtensions()
    var
        TelemetrySetup: Record "BJF Telemetry Setup";
        PublishedApplication: Record "NAV App Installed App";
        Labels: Text;
    begin
        TelemetrySetup.GetInstance();
        if not TelemetrySetup."Telemetry Enabled" then
            exit;
        if not TelemetrySetup."Track Extensions" then
            exit;

        if not PublishedApplication.FindSet() then
            exit;

        repeat
            Labels := this.BuildLabels(
                'environment', this.GetEnvironmentName(),
                'tenant_id', this.GetTenantId(),
                'company', this.GetCompanyName(),
                'app_id', Format(PublishedApplication."App ID", 0, 4),
                'app_name', PublishedApplication.Name,
                'app_version', Format(PublishedApplication."Version Major") + '.' +
                               Format(PublishedApplication."Version Minor") + '.' +
                               Format(PublishedApplication."Version Build") + '.' +
                               Format(PublishedApplication."Version Revision"),
                'publisher', PublishedApplication.Publisher
            );

            this.CreateLogEntry(
                Enum::"BJF Telemetry Type"::ExtensionInstalled,
                'bc_extension_installed',
                Labels,
                1
            );
        until PublishedApplication.Next() = 0;
    end;

    /// <summary>
    /// Records environment information as telemetry.
    /// </summary>
    procedure RecordEnvironmentInfo()
    var
        TelemetrySetup: Record "BJF Telemetry Setup";
        EnvironmentInformation: Codeunit "Environment Information";
        Labels: Text;
    begin
        TelemetrySetup.GetInstance();
        if not TelemetrySetup."Telemetry Enabled" then
            exit;

        Labels := this.BuildLabels(
            'environment', this.GetEnvironmentName(),
            'tenant_id', this.GetTenantId(),
            'company', this.GetCompanyName(),
            'is_saas', Format(EnvironmentInformation.IsSaaS(), 0, 9),
            'is_production', Format(EnvironmentInformation.IsProduction(), 0, 9),
            'is_sandbox', Format(EnvironmentInformation.IsSandbox(), 0, 9),
            'app_version', this.GetApplicationVersion()
        );

        this.CreateLogEntry(
            Enum::"BJF Telemetry Type"::EnvironmentInfo,
            'bc_environment_info',
            Labels,
            1
        );
    end;

    /// <summary>
    /// Records an error event.
    /// </summary>
    /// <param name="ErrorMessage">The error message.</param>
    /// <param name="SourceProcedure">The procedure where the error occurred.</param>
    procedure RecordError(ErrorMessage: Text; SourceProcedure: Text)
    var
        TelemetrySetup: Record "BJF Telemetry Setup";
        Labels: Text;
    begin
        TelemetrySetup.GetInstance();
        if not TelemetrySetup."Telemetry Enabled" then
            exit;
        if not TelemetrySetup."Track Errors" then
            exit;

        Labels := this.BuildLabels(
            'environment', this.GetEnvironmentName(),
            'tenant_id', this.GetTenantId(),
            'company', this.GetCompanyName(),
            'source', SourceProcedure,
            'error_hash', Format(ErrorMessage),
            'error_type', this.GetErrorType(ErrorMessage),
            'app_version', this.GetApplicationVersion()
        );

        this.CreateLogEntry(
            Enum::"BJF Telemetry Type"::Error,
            'bc_error',
            Labels,
            1
        );
    end;

    /// <summary>
    /// Records a test metric for verifying telemetry setup.
    /// </summary>
    procedure RecordTestMetric()
    var
        EnvironmentInformation: Codeunit "Environment Information";
        Labels: Text;
    begin
        Labels := this.BuildLabels(
            'environment', this.GetEnvironmentName(),
            'tenant_id', this.GetTenantId(),
            'company', this.GetCompanyName(),
            'is_saas', Format(EnvironmentInformation.IsSaaS(), 0, 9),
            'is_production', Format(EnvironmentInformation.IsProduction(), 0, 9),
            'test_type', 'connection_test',
            'app_version', this.GetApplicationVersion()
        );

        this.CreateLogEntry(
            Enum::"BJF Telemetry Type"::EnvironmentInfo,
            'bc_test',
            Labels,
            1
        );
    end;

    /// <summary>
    /// Forces recording of installed extensions, bypassing the enabled check.
    /// </summary>
    procedure ForceRecordInstalledExtensions()
    var
        PublishedApplication: Record "NAV App Installed App";
        Labels: Text;
    begin
        if not PublishedApplication.FindSet() then
            exit;

        repeat
            Labels := this.BuildLabels(
                'environment', this.GetEnvironmentName(),
                'tenant_id', this.GetTenantId(),
                'company', this.GetCompanyName(),
                'app_id', Format(PublishedApplication."App ID", 0, 4),
                'app_name', PublishedApplication.Name,
                'app_version', Format(PublishedApplication."Version Major") + '.' +
                               Format(PublishedApplication."Version Minor") + '.' +
                               Format(PublishedApplication."Version Build") + '.' +
                               Format(PublishedApplication."Version Revision"),
                'publisher', PublishedApplication.Publisher
            );

            this.CreateLogEntry(
                Enum::"BJF Telemetry Type"::ExtensionInstalled,
                'bc_extension_installed',
                Labels,
                1
            );
        until PublishedApplication.Next() = 0;
    end;

    /// <summary>
    /// Forces recording of environment information, bypassing the enabled check.
    /// </summary>
    procedure ForceRecordEnvironmentInfo()
    var
        EnvironmentInformation: Codeunit "Environment Information";
        Labels: Text;
    begin
        Labels := this.BuildLabels(
            'environment', this.GetEnvironmentName(),
            'tenant_id', this.GetTenantId(),
            'company', this.GetCompanyName(),
            'is_saas', Format(EnvironmentInformation.IsSaaS(), 0, 9),
            'is_production', Format(EnvironmentInformation.IsProduction(), 0, 9),
            'is_sandbox', Format(EnvironmentInformation.IsSandbox(), 0, 9),
            'app_version', this.GetApplicationVersion()
        );

        this.CreateLogEntry(
            Enum::"BJF Telemetry Type"::EnvironmentInfo,
            'bc_environment_info',
            Labels,
            1
        );
    end;

    /// <summary>
    /// Builds the InfluxDB line protocol payload from unsent log entries.
    /// </summary>
    /// <returns>The formatted InfluxDB line protocol payload.</returns>
    procedure BuildLineProtocolPayload(): Text
    var
        TelemetryLogEntry: Record "BJF Telemetry Log Entry";
        PayloadBuilder: TextBuilder;
        LineProtocol: Text;
        LineFeed: Char;
    begin
        TelemetryLogEntry.SetRange(Sent, false);
        if not TelemetryLogEntry.FindSet() then
            exit('');

        LineFeed := 10; // LF character - InfluxDB requires LF only, not CRLF

        repeat
            LineProtocol := this.FormatLineProtocol(
                TelemetryLogEntry."Metric Name",
                TelemetryLogEntry.Labels,
                TelemetryLogEntry.Value,
                TelemetryLogEntry."Timestamp Nanoseconds"
            );
            PayloadBuilder.Append(LineProtocol);
            PayloadBuilder.Append(LineFeed);
        until TelemetryLogEntry.Next() = 0;

        exit(PayloadBuilder.ToText().TrimEnd());
    end;

    /// <summary>
    /// Marks log entries as sent.
    /// </summary>
    /// <param name="Success">Whether the send was successful.</param>
    /// <param name="ErrorMessage">Error message if send failed.</param>
    procedure MarkEntriesAsSent(Success: Boolean; ErrorMessage: Text)
    var
        TelemetryLogEntry: Record "BJF Telemetry Log Entry";
    begin
        TelemetryLogEntry.SetRange(Sent, false);
        if not TelemetryLogEntry.FindSet() then
            exit;

        repeat
            TelemetryLogEntry.Sent := Success;
            if Success then
                TelemetryLogEntry."Sent At" := CurrentDateTime()
            else
                TelemetryLogEntry."Error Message" := CopyStr(ErrorMessage, 1, MaxStrLen(TelemetryLogEntry."Error Message"));
            TelemetryLogEntry.Modify(false);
        until TelemetryLogEntry.Next() = 0;
    end;

    /// <summary>
    /// Deletes old sent entries to prevent table growth.
    /// </summary>
    /// <param name="DaysToKeep">Number of days to keep sent entries.</param>
    procedure CleanupOldEntries(DaysToKeep: Integer)
    var
        TelemetryLogEntry: Record "BJF Telemetry Log Entry";
        CutoffDateTime: DateTime;
    begin
        CutoffDateTime := CreateDateTime(Today() - DaysToKeep, 0T);

        TelemetryLogEntry.SetRange(Sent, true);
        TelemetryLogEntry.SetFilter("Sent At", '<%1', CutoffDateTime);
        if not TelemetryLogEntry.IsEmpty() then
            TelemetryLogEntry.DeleteAll(false);
    end;

    local procedure CreateLogEntry(TelemetryType: Enum "BJF Telemetry Type"; MetricName: Text; Labels: Text; Value: Decimal)
    var
        TelemetryLogEntry: Record "BJF Telemetry Log Entry";
    begin
        TelemetryLogEntry.Init();
        TelemetryLogEntry."Telemetry Type" := TelemetryType;
        TelemetryLogEntry."Metric Name" := CopyStr(MetricName, 1, MaxStrLen(TelemetryLogEntry."Metric Name"));
        TelemetryLogEntry.Labels := CopyStr(Labels, 1, MaxStrLen(TelemetryLogEntry.Labels));
        TelemetryLogEntry.Value := Value;
        TelemetryLogEntry.Insert(true);
    end;

    local procedure FormatLineProtocol(MetricName: Text; Labels: Text; Value: Decimal; TimestampNs: BigInteger): Text
    begin
        exit(StrSubstNo(this.LineProtocolTok, MetricName, Labels, Format(Value, 0, 9), Format(TimestampNs)));
    end;

    local procedure EscapeLabelValue(Value: Text): Text
    begin
        Value := Value.Replace('\', '\\');
        Value := Value.Replace(' ', '\ ');
        Value := Value.Replace(',', '\,');
        Value := Value.Replace('=', '\=');
        exit(Value);
    end;

    local procedure GetEnvironmentName(): Text
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        exit(EnvironmentInformation.GetEnvironmentName());
    end;

    local procedure GetApplicationVersion(): Text
    var
        ApplicationSystemConstants: Codeunit "Application System Constants";
    begin
        exit(ApplicationSystemConstants.ApplicationVersion());
    end;

    local procedure GetTenantId(): Text
    begin
        exit(Database.TenantId());
    end;

    local procedure GetCompanyName(): Text
    begin
        exit(CompanyName());
    end;

    local procedure GetErrorType(ErrorMessage: Text): Text
    begin
        if ErrorMessage.Contains('permission') or ErrorMessage.Contains('Permission') then
            exit('Permission');
        if ErrorMessage.Contains('lock') or ErrorMessage.Contains('Lock') then
            exit('Locking');
        if ErrorMessage.Contains('timeout') or ErrorMessage.Contains('Timeout') then
            exit('Timeout');
        if ErrorMessage.Contains('connection') or ErrorMessage.Contains('Connection') then
            exit('Connection');
        exit('Other');
    end;

    local procedure BuildLabels(
        Label1Key: Text; Label1Value: Text;
        Label2Key: Text; Label2Value: Text;
        Label3Key: Text; Label3Value: Text;
        Label4Key: Text; Label4Value: Text;
        Label5Key: Text; Label5Value: Text;
        Label6Key: Text; Label6Value: Text;
        Label7Key: Text; Label7Value: Text): Text
    var
        LabelBuilder: TextBuilder;
    begin
        LabelBuilder.Append(StrSubstNo(this.LabelPairTok, Label1Key, this.EscapeLabelValue(Label1Value)));
        LabelBuilder.Append(StrSubstNo(this.LabelSeparatorTok, Label2Key, this.EscapeLabelValue(Label2Value)));
        LabelBuilder.Append(StrSubstNo(this.LabelSeparatorTok, Label3Key, this.EscapeLabelValue(Label3Value)));
        LabelBuilder.Append(StrSubstNo(this.LabelSeparatorTok, Label4Key, this.EscapeLabelValue(Label4Value)));
        LabelBuilder.Append(StrSubstNo(this.LabelSeparatorTok, Label5Key, this.EscapeLabelValue(Label5Value)));
        LabelBuilder.Append(StrSubstNo(this.LabelSeparatorTok, Label6Key, this.EscapeLabelValue(Label6Value)));
        LabelBuilder.Append(StrSubstNo(this.LabelSeparatorTok, Label7Key, this.EscapeLabelValue(Label7Value)));
        exit(LabelBuilder.ToText());
    end;
}
