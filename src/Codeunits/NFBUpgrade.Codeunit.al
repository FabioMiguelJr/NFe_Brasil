codeunit 50124 "NFB Upgrade"
{
    Subtype = Upgrade;

    var
        TaxDueDatesTagTok: Label 'NFB-TaxDueDates-20261014', Locked = true;

    trigger OnUpgradePerCompany()
    begin
        UpgradeSetupPhase3();
        UpgradeTaxDueDatesPhase5();
    end;

    local procedure UpgradeTaxDueDatesPhase5()
    var
        NFBInstall: Codeunit "NFB Install";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        // Version 1.3.0.0 added the monthly settlement; the install code does not run on upgrade.
        // The tag keeps later upgrades from bringing back rows the user deleted.
        if UpgradeTag.HasUpgradeTag(TaxDueDatesTagTok) then
            exit;
        NFBInstall.InsertTaxDueDateSetup();
        UpgradeTag.SetUpgradeTag(TaxDueDatesTagTok);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(TaxDueDatesTagTok);
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
