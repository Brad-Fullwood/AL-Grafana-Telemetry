namespace BradFullwood.GrafanaTelemetry;

/// <summary>
/// Dialog page for entering the Grafana API key securely.
/// </summary>
page 50102 "BJF API Key Dialog"
{
    Caption = 'Enter API Key';
    PageType = StandardDialog;
    Extensible = false;

    layout
    {
        area(Content)
        {
            group(ApiKeyGroup)
            {
                Caption = 'API Key';
                ShowCaption = false;

                field(ApiKeyField; ApiKeyValue)
                {
                    Caption = 'API Key';
                    ApplicationArea = All;
                    ToolTip = 'Enter the Grafana Cloud Access Token.';
                    ExtendedDatatype = Masked;

                    trigger OnValidate()
                    begin
                        this.ApiKeySecretText := ApiKeyValue;
                    end;
                }
            }
        }
    }

    var
        ApiKeyValue: Text[250];
        ApiKeySecretText: SecretText;

    /// <summary>
    /// Gets the entered API key as SecretText.
    /// </summary>
    /// <returns>The API key as SecretText.</returns>
    [NonDebuggable]
    procedure GetApiKey(): SecretText
    begin
        exit(this.ApiKeySecretText);
    end;
}
