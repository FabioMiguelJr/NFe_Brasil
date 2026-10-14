table 50122 "NFB Tax Settlement Line"
{
    Caption = 'NF-e Tax Settlement Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Settlement No."; Code[20])
        {
            Caption = 'Settlement No.';
            TableRelation = "NFB Tax Settlement Header";
        }
        field(2; "Tax Type"; Enum "NFB Tax Type")
        {
            Caption = 'Tax Type';
        }
        field(3; "State Code"; Code[2])
        {
            Caption = 'UF';
            ToolTip = 'Specifies the state the tax is owed to. Blank for the taxes of the issuer''s own state and for federal taxes; filled for ST, DIFAL and FCP owed to other states.';
        }
        field(10; "Output Tax"; Decimal)
        {
            Caption = 'Output Tax (Debits)';
            AutoFormatType = 1;
            Editable = false;
            ToolTip = 'Specifies the tax posted on sales in the period, net of sales credit memos.';
        }
        field(11; "Input Tax"; Decimal)
        {
            Caption = 'Input Tax (Credits)';
            AutoFormatType = 1;
            Editable = false;
            ToolTip = 'Specifies the recoverable tax posted on purchases in the period, net of purchase credit memos.';
        }
        field(12; "Other Debits"; Decimal)
        {
            Caption = 'Other Debits';
            AutoFormatType = 1;
            ToolTip = 'Specifies manual adjustments that increase the tax due, such as credit reversals. They are posted against the adjustment account.';

            trigger OnValidate()
            begin
                TestStatusOpen();
                UpdateBalance();
            end;
        }
        field(13; "Other Credits"; Decimal)
        {
            Caption = 'Other Credits';
            AutoFormatType = 1;
            ToolTip = 'Specifies manual adjustments that reduce the tax due, such as extemporaneous credits. They are posted against the adjustment account.';

            trigger OnValidate()
            begin
                TestStatusOpen();
                UpdateBalance();
            end;
        }
        field(14; "Previous Credit Balance"; Decimal)
        {
            Caption = 'Previous Credit Balance';
            AutoFormatType = 1;
            MinValue = 0;
            ToolTip = 'Specifies the credit carried forward from the previous posted settlement. For the first settlement in Business Central, enter the opening credit balance here; it must already be in the recoverable account.';

            trigger OnValidate()
            begin
                TestStatusOpen();
                UpdateBalance();
            end;
        }
        field(15; Balance; Decimal)
        {
            Caption = 'Balance';
            AutoFormatType = 1;
            Editable = false;
            ToolTip = 'Specifies debits minus credits. A positive balance is paid; a negative balance is carried forward.';
        }
        field(16; "Amount Payable"; Decimal)
        {
            Caption = 'Amount Payable';
            AutoFormatType = 1;
            Editable = false;
        }
        field(17; "Credit Carried Forward"; Decimal)
        {
            Caption = 'Credit Carried Forward';
            AutoFormatType = 1;
            Editable = false;
        }
        field(20; "Guide Type"; Enum "NFB Guide Type")
        {
            Caption = 'Guide Type';
        }
        field(21; "Vendor No."; Code[20])
        {
            Caption = 'Tax Authority Vendor No.';
            TableRelation = Vendor;
            ToolTip = 'Specifies the vendor that represents the tax authority. The payable is created for this vendor.';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(22; "Revenue Code"; Code[10])
        {
            Caption = 'Revenue Code';
            ToolTip = 'Specifies the revenue code of the guide (código de receita), for example 8109 for PIS or 2172 for COFINS under the cumulative regime.';
        }
        field(23; "Due Date"; Date)
        {
            Caption = 'Due Date';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(24; "Adjustment Account"; Code[20])
        {
            Caption = 'Adjustment Account';
            TableRelation = "G/L Account" where("Account Type" = const(Posting), Blocked = const(false));
            ToolTip = 'Specifies the G/L account posted against other debits and other credits.';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(30; "Vendor Ledger Entry No."; Integer)
        {
            Caption = 'Vendor Ledger Entry No.';
            Editable = false;
            TableRelation = "Vendor Ledger Entry";
        }
        field(31; "No. of Entries"; Integer)
        {
            Caption = 'No. of Documents';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("NFB Tax Settlement Entry" where("Settlement No." = field("Settlement No."), "Tax Type" = field("Tax Type"), "State Code" = field("State Code")));
        }
    }

    keys
    {
        key(PK; "Settlement No.", "Tax Type", "State Code") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        TestStatusOpen();
    end;

    trigger OnDelete()
    var
        NFBTaxSettlementEntry: Record "NFB Tax Settlement Entry";
    begin
        TestStatusOpen();
        NFBTaxSettlementEntry.SetRange("Settlement No.", "Settlement No.");
        NFBTaxSettlementEntry.SetRange("Tax Type", "Tax Type");
        NFBTaxSettlementEntry.SetRange("State Code", "State Code");
        NFBTaxSettlementEntry.DeleteAll();
    end;

    procedure UpdateBalance()
    begin
        "Output Tax" := Round("Output Tax");
        "Input Tax" := Round("Input Tax");
        "Other Debits" := Round("Other Debits");
        "Other Credits" := Round("Other Credits");
        "Previous Credit Balance" := Round("Previous Credit Balance");
        Balance := "Output Tax" + "Other Debits" - "Input Tax" - "Other Credits" - "Previous Credit Balance";
        "Amount Payable" := 0;
        "Credit Carried Forward" := 0;
        if Balance > 0 then
            "Amount Payable" := Balance
        else
            "Credit Carried Forward" := -Balance;
    end;

    /// <summary>
    /// Part of the period's debits settled with credits; it is credited to the recoverable account when posting.
    /// </summary>
    procedure CreditsUsed(): Decimal
    begin
        exit("Output Tax" + "Other Debits" - "Other Credits" - "Amount Payable");
    end;

    procedure ShowEntries()
    var
        NFBTaxSettlementEntry: Record "NFB Tax Settlement Entry";
    begin
        NFBTaxSettlementEntry.SetRange("Settlement No.", "Settlement No.");
        NFBTaxSettlementEntry.SetRange("Tax Type", "Tax Type");
        NFBTaxSettlementEntry.SetRange("State Code", "State Code");
        Page.Run(Page::"NFB Tax Settlement Entries", NFBTaxSettlementEntry);
    end;

    local procedure TestStatusOpen()
    var
        NFBTaxSettlementHeader: Record "NFB Tax Settlement Header";
    begin
        if NFBTaxSettlementHeader.Get("Settlement No.") then
            NFBTaxSettlementHeader.TestStatusOpen();
    end;
}
