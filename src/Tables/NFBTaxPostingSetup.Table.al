table 50208 "NFB Tax Posting Setup"
{
    Caption = 'NF-e Tax Posting Setup';
    DataClassification = CustomerContent;
    DrillDownPageId = "NFB Tax Posting Setup";
    LookupPageId = "NFB Tax Posting Setup";

    fields
    {
        field(1; "Tax Type"; Enum "NFB Tax Type")
        {
            Caption = 'Tax Type';
        }
        field(2; "Payable Account"; Code[20])
        {
            Caption = 'Tax Payable Account';
            TableRelation = "G/L Account" where("Account Type" = const(Posting), Blocked = const(false));
        }
        field(3; "Sales Deduction Account"; Code[20])
        {
            Caption = 'Sales Deduction Account';
            ToolTip = 'Debited for taxes included in the price (ICMS, FCP, PIS, COFINS, IBS, CBS). Leave blank for taxes charged on top of the price (IPI, ST).';
            TableRelation = "G/L Account" where("Account Type" = const(Posting), Blocked = const(false));
        }
        field(4; "Recoverable Account"; Code[20])
        {
            Caption = 'Recoverable (Credit) Account';
            ToolTip = 'Debited on purchases when the tax generates credit. Leave blank when there is no credit (e.g. PIS/COFINS under Lucro Presumido).';
            TableRelation = "G/L Account" where("Account Type" = const(Posting), Blocked = const(false));
        }
        field(5; "Purchase Cost Account"; Code[20])
        {
            Caption = 'Purchase Cost Account';
            ToolTip = 'Credited when a tax included in the purchase price is moved to the recoverable account, and debited for non-recoverable taxes charged on top of the price.';
            TableRelation = "G/L Account" where("Account Type" = const(Posting), Blocked = const(false));
        }
        field(6; "Included in Price"; Boolean)
        {
            Caption = 'Included in Price';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Tax Type") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        "Included in Price" := IsIncludedInPrice("Tax Type");
    end;

    procedure IsIncludedInPrice(TaxType: Enum "NFB Tax Type"): Boolean
    begin
        exit(not (TaxType in [TaxType::IPI, TaxType::"ICMS ST", TaxType::"FCP ST", TaxType::II]));
    end;
}
