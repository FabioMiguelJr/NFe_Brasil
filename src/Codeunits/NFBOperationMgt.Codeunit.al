codeunit 50200 "NFB Operation Mgt"
{
    procedure ApplyToSalesHeader(var SalesHeader: Record "Sales Header")
    var
        NFBOperationType: Record "NFB Operation Type";
        Customer: Record Customer;
    begin
        if not NFBOperationType.Get(SalesHeader."NFB Operation Type") then
            exit;
        SalesHeader."NFB Nature of Operation" := NFBOperationType."Nature of Operation";
        SalesHeader."NFB Purpose" := NFBOperationType.Purpose;
        SalesHeader."NFB Presence Indicator" := NFBOperationType."Presence Indicator";
        if Customer.Get(SalesHeader."Bill-to Customer No.") then
            SalesHeader."NFB Final Consumer" := Customer."NFB Final Consumer" or (Customer."NFB IE Indicator" = Customer."NFB IE Indicator"::"Non-Contributor");
    end;

    procedure ApplyToPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    var
        NFBOperationType: Record "NFB Operation Type";
    begin
        if not NFBOperationType.Get(PurchaseHeader."NFB Operation Type") then
            exit;
        PurchaseHeader."NFB Nature of Operation" := NFBOperationType."Nature of Operation";
        PurchaseHeader."NFB Purpose" := NFBOperationType.Purpose;
        PurchaseHeader."NFB Presence Indicator" := NFBOperationType."Presence Indicator";
    end;

    procedure ApplyToTransferHeader(var TransferHeader: Record "Transfer Header")
    var
        NFBOperationType: Record "NFB Operation Type";
    begin
        if not NFBOperationType.Get(TransferHeader."NFB Operation Type") then
            exit;
        TransferHeader."NFB Nature of Operation" := NFBOperationType."Nature of Operation";
        TransferHeader."NFB Purpose" := NFBOperationType.Purpose;
        TransferHeader."NFB Presence Indicator" := NFBOperationType."Presence Indicator";
        TransferHeader."NFB Final Consumer" := false;
    end;

    procedure GetDestinationId(IssuerUF: Code[2]; RecipientUF: Code[2]; RecipientCountryCode: Code[10]): Enum "NFB Destination Id"
    var
        DestinationId: Enum "NFB Destination Id";
    begin
        if IsForeignCountry(RecipientCountryCode) then
            exit(DestinationId::Exterior);
        if (RecipientUF = '') or (RecipientUF = IssuerUF) then
            exit(DestinationId::Internal);
        exit(DestinationId::Interstate);
    end;

    procedure IsForeignCountry(CountryCode: Code[10]): Boolean
    var
        CountryRegion: Record "Country/Region";
    begin
        if CountryCode = '' then
            exit(false);
        if CountryCode in ['BR', 'BRA'] then
            exit(false);
        if CountryRegion.Get(CountryCode) then
            exit(CountryRegion."NFB BACEN Code" <> '1058');
        exit(true);
    end;

    procedure GetIssuerUF(LocationCode: Code[10]): Code[2]
    var
        Location: Record Location;
        CompanyInformation: Record "Company Information";
    begin
        if Location.Get(LocationCode) then
            if Location."NFB CNPJ" <> '' then
                exit(Location."NFB UF");
        CompanyInformation.Get();
        exit(CompanyInformation."NFB UF");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateEvent', 'Sell-to Customer No.', false, false)]
    local procedure SalesHeaderOnAfterValidateSellTo(var Rec: Record "Sales Header")
    var
        NFBSetup: Record "NFB Setup";
    begin
        if Rec.IsTemporary() then
            exit;
        if not NFBSetup.Get() then
            exit;
        if Rec."Document Type" in [Rec."Document Type"::"Credit Memo", Rec."Document Type"::"Return Order"] then
            Rec."NFB Operation Type" := NFBSetup."Sales Return Operation Type"
        else
            Rec."NFB Operation Type" := NFBSetup."Sales Operation Type";
        ApplyToSalesHeader(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterValidateEvent', 'Buy-from Vendor No.', false, false)]
    local procedure PurchaseHeaderOnAfterValidateBuyFrom(var Rec: Record "Purchase Header")
    var
        NFBSetup: Record "NFB Setup";
    begin
        if Rec.IsTemporary() then
            exit;
        if not NFBSetup.Get() then
            exit;
        if Rec."Document Type" in [Rec."Document Type"::"Credit Memo", Rec."Document Type"::"Return Order"] then
            Rec."NFB Operation Type" := NFBSetup."Purch. Return Operation Type"
        else
            Rec."NFB Operation Type" := NFBSetup."Purchase Operation Type";
        ApplyToPurchaseHeader(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnAfterInsertEvent', '', false, false)]
    local procedure TransferHeaderOnAfterInsert(var Rec: Record "Transfer Header"; RunTrigger: Boolean)
    var
        NFBSetup: Record "NFB Setup";
    begin
        if Rec.IsTemporary() or (Rec."NFB Operation Type" <> '') then
            exit;
        if not NFBSetup.Get() then
            exit;
        if NFBSetup."Transfer Operation Type" = '' then
            exit;
        Rec."NFB Operation Type" := NFBSetup."Transfer Operation Type";
        ApplyToTransferHeader(Rec);
        Rec.Modify();
    end;
}
