namespace BradFullwood.GrafanaTelemetry;

/// <summary>
/// Scheduler codeunit for processing and sending telemetry via Job Queue.
/// </summary>
codeunit 50103 "BJF Telemetry Scheduler"
{
    Access = Internal;
    TableNo = "Job Queue Entry";

    var
        JobQueueCategoryCodeTok: Label 'TELEMETRY', Locked = true;
        JobQueueDescriptionTxt: Label 'Send Telemetry to Grafana';
        JobQueueCategoryDescTxt: Label 'Grafana Telemetry';
        NoTelemetryToSendTxt: Label 'No telemetry to send', Locked = true;
        SuccessTxt: Label 'Success', Locked = true;
        SuccessForcedTxt: Label 'Success (forced)', Locked = true;
        FailedTxt: Label 'Failed: %1', Locked = true, Comment = '%1 = Error message';
        FailedAtStepTxt: Label 'Failed at %1: %2', Locked = true, Comment = '%1 = Step name, %2 = Error message';

    trigger OnRun()
    begin
        this.ProcessAndSendTelemetry();
    end;

    /// <summary>
    /// Processes pending telemetry entries and sends them to Grafana.
    /// </summary>
    procedure ProcessAndSendTelemetry()
    var
        TelemetrySetup: Record "BJF Telemetry Setup";
        TelemetryCollector: Codeunit "BJF Telemetry Collector";
        GrafanaHttpClient: Codeunit "BJF Grafana Http Client";
        Payload: Text;
        Success: Boolean;
        ErrorMessage: Text;
    begin
        TelemetrySetup.GetInstance();
        if not TelemetrySetup."Telemetry Enabled" then
            exit;

        TelemetryCollector.RecordEnvironmentInfo();
        TelemetryCollector.RecordInstalledExtensions();

        Payload := TelemetryCollector.BuildLineProtocolPayload();
        if Payload = '' then begin
            this.UpdateSendStatus(TelemetrySetup, this.NoTelemetryToSendTxt);
            exit;
        end;

        Success := GrafanaHttpClient.SendTelemetry(Payload);
        if Success then begin
            TelemetryCollector.MarkEntriesAsSent(true, '');
            this.UpdateSendStatus(TelemetrySetup, this.SuccessTxt);
        end else begin
            ErrorMessage := GetLastErrorText();
            TelemetryCollector.MarkEntriesAsSent(false, ErrorMessage);
            this.UpdateSendStatus(TelemetrySetup, StrSubstNo(this.FailedTxt, ErrorMessage));
        end;

        TelemetryCollector.CleanupOldEntries(7);
    end;

    /// <summary>
    /// Creates or updates the Job Queue Entry for scheduled telemetry sending.
    /// </summary>
    procedure CreateJobQueueEntry()
    var
        TelemetrySetup: Record "BJF Telemetry Setup";
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueCategory: Record "Job Queue Category";
    begin
        TelemetrySetup.GetInstance();

        if not JobQueueCategory.Get(this.JobQueueCategoryCodeTok) then begin
            JobQueueCategory.Init();
            JobQueueCategory.Code := this.JobQueueCategoryCodeTok;
            JobQueueCategory.Description := this.JobQueueCategoryDescTxt;
            JobQueueCategory.Insert(false);
        end;

        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"BJF Telemetry Scheduler");
        if JobQueueEntry.FindFirst() then begin
            if JobQueueEntry.Status = JobQueueEntry.Status::"On Hold" then begin
                JobQueueEntry.Status := JobQueueEntry.Status::Ready;
                JobQueueEntry."No. of Minutes between Runs" := TelemetrySetup."Send Interval Minutes";
                JobQueueEntry.Modify(false);
            end;
            exit;
        end;

        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"BJF Telemetry Scheduler";
        JobQueueEntry.Description := this.JobQueueDescriptionTxt;
        JobQueueEntry."Job Queue Category Code" := this.JobQueueCategoryCodeTok;
        JobQueueEntry."No. of Minutes between Runs" := TelemetrySetup."Send Interval Minutes";
        JobQueueEntry."Recurring Job" := true;
        JobQueueEntry."Run on Mondays" := true;
        JobQueueEntry."Run on Tuesdays" := true;
        JobQueueEntry."Run on Wednesdays" := true;
        JobQueueEntry."Run on Thursdays" := true;
        JobQueueEntry."Run on Fridays" := true;
        JobQueueEntry."Run on Saturdays" := true;
        JobQueueEntry."Run on Sundays" := true;
        JobQueueEntry.Status := JobQueueEntry.Status::Ready;
        JobQueueEntry.Insert(false);
    end;

    /// <summary>
    /// Removes the Job Queue Entry for telemetry sending.
    /// </summary>
    procedure RemoveJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"BJF Telemetry Scheduler");
        if not JobQueueEntry.IsEmpty() then
            JobQueueEntry.DeleteAll(false);
    end;

    /// <summary>
    /// Forces collection of environment info and extensions, then sends immediately.
    /// Bypasses the Telemetry Enabled check - useful for testing.
    /// </summary>
    /// <returns>The number of telemetry entries sent.</returns>
    procedure ForceCollectAndSend(): Integer
    var
        TelemetrySetup: Record "BJF Telemetry Setup";
        TelemetryCollector: Codeunit "BJF Telemetry Collector";
        GrafanaHttpClient: Codeunit "BJF Grafana Http Client";
        TelemetryLogEntry: Record "BJF Telemetry Log Entry";
        Payload: Text;
        Success: Boolean;
        ErrorMessage: Text;
        EntryCount: Integer;
        Step: Text;
    begin
        TelemetrySetup.GetInstance();

        Step := 'RecordEnvironmentInfo';
        TelemetryCollector.ForceRecordEnvironmentInfo();

        Step := 'RecordInstalledExtensions';
        TelemetryCollector.ForceRecordInstalledExtensions();

        Step := 'CountEntries';
        TelemetryLogEntry.SetRange(Sent, false);
        EntryCount := TelemetryLogEntry.Count();

        Step := 'BuildPayload';
        Payload := TelemetryCollector.BuildLineProtocolPayload();
        if Payload = '' then begin
            this.UpdateSendStatus(TelemetrySetup, this.NoTelemetryToSendTxt);
            exit(0);
        end;

        Step := 'SendTelemetry';
        Success := GrafanaHttpClient.SendTelemetry(Payload);
        if Success then begin
            TelemetryCollector.MarkEntriesAsSent(true, '');
            this.UpdateSendStatus(TelemetrySetup, this.SuccessForcedTxt);
        end else begin
            ErrorMessage := GetLastErrorText();
            TelemetryCollector.MarkEntriesAsSent(false, ErrorMessage);
            this.UpdateSendStatus(TelemetrySetup, StrSubstNo(this.FailedAtStepTxt, Step, ErrorMessage));
            exit(0);
        end;

        exit(EntryCount);
    end;

    local procedure UpdateSendStatus(var TelemetrySetup: Record "BJF Telemetry Setup"; Status: Text)
    begin
        TelemetrySetup."Last Send DateTime" := CurrentDateTime();
        TelemetrySetup."Last Send Status" := CopyStr(Status, 1, MaxStrLen(TelemetrySetup."Last Send Status"));
        TelemetrySetup.Modify(false);
    end;
}
