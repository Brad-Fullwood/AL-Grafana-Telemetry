namespace BradFullwood.GrafanaTelemetry;

/// <summary>
/// List page for viewing telemetry log entries.
/// </summary>
page 50101 "BJF Telemetry Log Entries"
{
    Caption = 'Telemetry Log Entries';
    PageType = List;
    SourceTable = "BJF Telemetry Log Entry";
    UsageCategory = Lists;
    ApplicationArea = All;
    Editable = false;
    Extensible = false;
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Entries)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique identifier for this telemetry entry.';
                }
                field("Telemetry Type"; Rec."Telemetry Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of telemetry event.';
                }
                field("Metric Name"; Rec."Metric Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the InfluxDB metric name.';
                }
                field(Labels; Rec.Labels)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the comma-separated label key-value pairs for the metric.';
                }
                field(Value; Rec.Value)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the metric value.';
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when this telemetry entry was created.';
                }
                field(Sent; Rec.Sent)
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates whether this entry has been sent to Grafana.';
                }
                field("Sent At"; Rec."Sent At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when this entry was sent to Grafana.';
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies any error message from the send attempt.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteSentEntries)
            {
                Caption = 'Delete Sent Entries';
                ToolTip = 'Delete all entries that have been successfully sent.';
                ApplicationArea = All;
                Image = Delete;

                trigger OnAction()
                var
                    TelemetryLogEntry: Record "BJF Telemetry Log Entry";
                begin
                    TelemetryLogEntry.SetRange(Sent, true);
                    if TelemetryLogEntry.IsEmpty() then begin
                        Message(this.NoSentEntriesMsg);
                        exit;
                    end;

                    if not Confirm(this.DeleteSentEntriesQst) then
                        exit;

                    TelemetryLogEntry.DeleteAll(false);
                    Message(this.EntriesDeletedMsg);
                end;
            }
            action(DeleteAllEntries)
            {
                Caption = 'Delete All Entries';
                ToolTip = 'Delete all telemetry log entries.';
                ApplicationArea = All;
                Image = Delete;

                trigger OnAction()
                var
                    TelemetryLogEntry: Record "BJF Telemetry Log Entry";
                begin
                    if TelemetryLogEntry.IsEmpty() then begin
                        Message(this.NoEntriesMsg);
                        exit;
                    end;

                    if not Confirm(this.DeleteAllEntriesQst) then
                        exit;

                    TelemetryLogEntry.DeleteAll(false);
                    Message(this.EntriesDeletedMsg);
                end;
            }
        }
    }

    var
        NoSentEntriesMsg: Label 'There are no sent entries to delete.';
        NoEntriesMsg: Label 'There are no entries to delete.';
        DeleteSentEntriesQst: Label 'Do you want to delete all sent entries?';
        DeleteAllEntriesQst: Label 'Do you want to delete all entries?';
        EntriesDeletedMsg: Label 'Entries have been deleted.';
}
