namespace BradFullwood.GrafanaTelemetry;

/// <summary>
/// Queue table for batching telemetry events before sending to Grafana.
/// </summary>
table 50101 "BJF Telemetry Log Entry"
{
    Caption = 'Telemetry Log Entry';
    DataClassification = CustomerContent;
    Extensible = false;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the unique identifier for this telemetry entry.';
            AutoIncrement = true;
        }
        field(10; "Telemetry Type"; Enum "BJF Telemetry Type")
        {
            Caption = 'Telemetry Type';
            ToolTip = 'Specifies the type of telemetry event.';
        }
        field(11; "Metric Name"; Text[100])
        {
            Caption = 'Metric Name';
            ToolTip = 'Specifies the InfluxDB metric name.';
        }
        field(12; Labels; Text[2048])
        {
            Caption = 'Labels';
            ToolTip = 'Specifies the comma-separated label key-value pairs for the metric.';
        }
        field(13; Value; Decimal)
        {
            Caption = 'Value';
            ToolTip = 'Specifies the metric value.';
            InitValue = 1;
        }
        field(20; "Created At"; DateTime)
        {
            Caption = 'Created At';
            ToolTip = 'Specifies when this telemetry entry was created.';
        }
        field(21; "Timestamp Nanoseconds"; BigInteger)
        {
            Caption = 'Timestamp (Nanoseconds)';
            ToolTip = 'Specifies the Unix timestamp in nanoseconds for InfluxDB.';
        }
        field(30; Sent; Boolean)
        {
            Caption = 'Sent';
            ToolTip = 'Indicates whether this entry has been sent to Grafana.';
        }
        field(31; "Sent At"; DateTime)
        {
            Caption = 'Sent At';
            ToolTip = 'Specifies when this entry was sent to Grafana.';
        }
        field(40; "Error Message"; Text[2048])
        {
            Caption = 'Error Message';
            ToolTip = 'Specifies any error message from the send attempt.';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Sent; Sent, "Created At")
        {
        }
    }

    trigger OnInsert()
    begin
        Rec."Created At" := CurrentDateTime();
        Rec."Timestamp Nanoseconds" := this.GetTimestampNanoseconds();
    end;

    local procedure GetTimestampNanoseconds(): BigInteger
    var
        EpochDateTime: DateTime;
        MillisecondsSinceEpoch: BigInteger;
    begin
        EpochDateTime := CreateDateTime(19700101D, 0T);
        MillisecondsSinceEpoch := CurrentDateTime() - EpochDateTime;
        exit(MillisecondsSinceEpoch * 1000000);
    end;
}
