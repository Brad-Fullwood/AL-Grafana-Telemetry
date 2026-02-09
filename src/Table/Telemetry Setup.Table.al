namespace BradFullwood.GrafanaTelemetry;

/// <summary>
/// Singleton table storing configuration for Grafana telemetry integration.
/// Uses IsolatedStorage for secure API key storage.
/// </summary>
table 50100 "BJF Telemetry Setup"
{
    Caption = 'Telemetry Setup';
    DataClassification = CustomerContent;
    Extensible = false;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            ToolTip = 'Specifies the primary key for the singleton record.';
        }
        field(10; "Grafana Endpoint"; Text[250])
        {
            Caption = 'Grafana Endpoint';
            ToolTip = 'Specifies the InfluxDB write endpoint URL (e.g., https://your-host/api/v2/write?org=myorg&bucket=mybucket&precision=ns).';

            trigger OnValidate()
            begin
                if Rec."Grafana Endpoint" <> '' then
                    if not Rec."Grafana Endpoint".StartsWith('https://') then
                        Error(this.EndpointMustBeHttpsErr);
            end;
        }
        field(11; "User ID"; Text[100])
        {
            Caption = 'User ID';
            ToolTip = 'Optional. Used for Grafana Cloud basic auth. Not required for InfluxDB token auth.';
        }
        field(12; "API Key Set"; Boolean)
        {
            Caption = 'API Key Set';
            ToolTip = 'Indicates whether the API key has been configured in secure storage.';
            Editable = false;
        }
        field(20; "Telemetry Enabled"; Boolean)
        {
            Caption = 'Telemetry Enabled';
            ToolTip = 'Specifies whether telemetry collection and sending is enabled.';
        }
        field(30; "Track User Logins"; Boolean)
        {
            Caption = 'Track User Logins';
            ToolTip = 'Specifies whether to track user login events.';
            InitValue = true;
        }
        field(31; "Track Extensions"; Boolean)
        {
            Caption = 'Track Extensions';
            ToolTip = 'Specifies whether to track installed extensions.';
            InitValue = true;
        }
        field(32; "Track Errors"; Boolean)
        {
            Caption = 'Track Errors';
            ToolTip = 'Specifies whether to track error events.';
            InitValue = true;
        }
        field(40; "Send Interval Minutes"; Integer)
        {
            Caption = 'Send Interval (Minutes)';
            ToolTip = 'Specifies how often telemetry data should be sent to Grafana in minutes.';
            InitValue = 5;
            MinValue = 1;
            MaxValue = 1440;
        }
        field(50; "Last Send DateTime"; DateTime)
        {
            Caption = 'Last Send Date/Time';
            ToolTip = 'Specifies the date and time when telemetry was last sent.';
            Editable = false;
        }
        field(51; "Last Send Status"; Text[250])
        {
            Caption = 'Last Send Status';
            ToolTip = 'Specifies the status of the last telemetry send operation.';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    var
        EndpointMustBeHttpsErr: Label 'The Grafana endpoint must use HTTPS.';

    /// <summary>
    /// Gets the singleton setup record, creating it if it doesn't exist.
    /// </summary>
    procedure GetInstance()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert(false);
        end;
    end;
}
