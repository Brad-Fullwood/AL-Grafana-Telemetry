namespace BradFullwood.GrafanaTelemetry;

/// <summary>
/// Event subscribers for capturing telemetry events.
/// Uses SingleInstance to maintain state across the session.
/// </summary>
codeunit 50102 "BJF Telemetry Event Subs"
{
    Access = Internal;
    SingleInstance = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", OnAfterLogin, '', false, false)]
    local procedure OnAfterLogin()
    var
        TelemetryCollector: Codeunit "BJF Telemetry Collector";
    begin
        TelemetryCollector.RecordUserLogin(UserSecurityId());
    end;
}
