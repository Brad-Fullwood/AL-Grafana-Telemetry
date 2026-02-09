namespace BradFullwood.GrafanaTelemetry;

/// <summary>
/// Permission set for Grafana Telemetry extension.
/// </summary>
permissionset 50100 "BJF Telemetry"
{
    Caption = 'Grafana Telemetry';
    Assignable = true;
    Permissions = table "BJF Telemetry Setup" = X,
        table "BJF Telemetry Log Entry" = X,
        tabledata "BJF Telemetry Setup" = RIMD,
        tabledata "BJF Telemetry Log Entry" = RIMD,
        page "BJF Telemetry Setup" = X,
        page "BJF Telemetry Log Entries" = X,
        page "BJF API Key Dialog" = X,
        codeunit "BJF Grafana Http Client" = X,
        codeunit "BJF Telemetry Collector" = X,
        codeunit "BJF Telemetry Event Subs" = X,
        codeunit "BJF Telemetry Scheduler" = X;
}
