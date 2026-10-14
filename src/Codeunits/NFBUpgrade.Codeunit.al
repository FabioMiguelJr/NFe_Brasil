codeunit 50124 "NFB Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    begin
        UpgradeSetupPhase3();
    end;

    local procedure UpgradeSetupPhase3()
    var
        NFBSetup: Record "NFB Setup";
    begin
        // InitValue is not applied to existing records. Version 1.2.0.0 added the PlugNotas fields:
        // start existing companies in the sandbox, never in the real API by accident.
        if not NFBSetup.Get() then
            exit;
        if NFBSetup."Status Query Minutes" <> 0 then
            exit;
        NFBSetup."Use PlugNotas Sandbox" := true;
        NFBSetup."Status Query Minutes" := 5;
        NFBSetup.Modify();
    end;
}
