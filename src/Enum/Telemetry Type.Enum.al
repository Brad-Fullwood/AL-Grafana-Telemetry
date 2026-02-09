namespace BradFullwood.GrafanaTelemetry;

/// <summary>
/// Defines the types of telemetry events that can be collected and sent to Grafana.
/// </summary>
enum 50100 "BJF Telemetry Type"
{
    Caption = 'Telemetry Type';
    Extensible = false;

    value(0; UserLogin)
    {
        Caption = 'User Login';
    }
    value(1; ExtensionInstalled)
    {
        Caption = 'Extension Installed';
    }
    value(2; EnvironmentInfo)
    {
        Caption = 'Environment Info';
    }
    value(3; Error)
    {
        Caption = 'Error';
    }
}
