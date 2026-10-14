table 50123 "NFB Tax Due Date Setup"
{
    Caption = 'NF-e Tax Due Date Setup';
    DataClassification = CustomerContent;
    DrillDownPageId = "NFB Tax Due Date Setup";
    LookupPageId = "NFB Tax Due Date Setup";

    fields
    {
        field(1; "Tax Type"; Enum "NFB Tax Type")
        {
            Caption = 'Tax Type';
        }
        field(2; "State Code"; Code[2])
        {
            Caption = 'UF';
            ToolTip = 'Specifies the state for ST, DIFAL and FCP owed to another state. Leave it blank for the default row of the tax.';
        }
        field(3; "Guide Type"; Enum "NFB Guide Type")
        {
            Caption = 'Guide Type';
        }
        field(4; "Vendor No."; Code[20])
        {
            Caption = 'Tax Authority Vendor No.';
            TableRelation = Vendor;
            ToolTip = 'Specifies the vendor that represents the tax authority (Receita Federal, SEFAZ-RJ or the SEFAZ of another state). The payable of the guide is created for it.';
        }
        field(5; "Revenue Code"; Code[10])
        {
            Caption = 'Revenue Code';
            ToolTip = 'Specifies the revenue code printed on the guide (código de receita).';
        }
        field(6; "Due Day"; Integer)
        {
            Caption = 'Due Day';
            MinValue = 0;
            MaxValue = 31;
            ToolTip = 'Specifies the day of the month the guide is due. Leave it at 0 to enter the due date on the settlement line.';
        }
        field(7; "Months After Period"; Integer)
        {
            Caption = 'Months After Period';
            MinValue = 0;
            InitValue = 1;
            ToolTip = 'Specifies how many months after the settled month the guide is due. 1 means the following month.';
        }
        field(8; "Non-Working Day Rule"; Option)
        {
            Caption = 'Non-Working Day Rule';
            OptionMembers = "Previous Working Day","Next Working Day","Keep Date";
            OptionCaption = 'Previous Working Day,Next Working Day,Keep Date';
            ToolTip = 'Specifies how a due date that falls on a weekend or holiday is moved. Federal taxes are usually anticipated to the previous working day.';
        }
        field(9; "Base Calendar Code"; Code[10])
        {
            Caption = 'Base Calendar Code';
            TableRelation = "Base Calendar";
            ToolTip = 'Specifies the calendar with the holidays. Weekends are always non-working days.';
        }
        field(10; "Adjustment Account"; Code[20])
        {
            Caption = 'Adjustment Account';
            TableRelation = "G/L Account" where("Account Type" = const(Posting), Blocked = const(false));
            ToolTip = 'Specifies the G/L account posted against the other debits and other credits of the settlement.';
        }
    }

    keys
    {
        key(PK; "Tax Type", "State Code") { Clustered = true; }
    }

    /// <summary>
    /// Finds the row of the state, or the default row of the tax (blank state).
    /// </summary>
    procedure FindForTax(TaxType: Enum "NFB Tax Type"; StateCode: Code[2]): Boolean
    begin
        if StateCode <> '' then
            if Get(TaxType, StateCode) then
                exit(true);
        exit(Get(TaxType, ''));
    end;

    procedure CalcDueDate(PeriodEndingDate: Date): Date
    var
        MonthStart: Date;
        MonthEnd: Date;
        DueDate: Date;
        DayNo: Integer;
        Attempts: Integer;
    begin
        if ("Due Day" = 0) or (PeriodEndingDate = 0D) then
            exit(0D);
        MonthStart := CalcDate('<-CM>', PeriodEndingDate);
        if "Months After Period" > 0 then
            MonthStart := CalcDate(StrSubstNo('<%1M>', "Months After Period"), MonthStart);
        MonthEnd := CalcDate('<CM>', MonthStart);
        DayNo := "Due Day";
        if DayNo > Date2DMY(MonthEnd, 1) then
            DayNo := Date2DMY(MonthEnd, 1);
        DueDate := DMY2Date(DayNo, Date2DMY(MonthStart, 2), Date2DMY(MonthStart, 3));
        if "Non-Working Day Rule" = "Non-Working Day Rule"::"Keep Date" then
            exit(DueDate);
        while IsNonWorkingDay(DueDate) and (Attempts < 31) do begin
            if "Non-Working Day Rule" = "Non-Working Day Rule"::"Previous Working Day" then
                DueDate := DueDate - 1
            else
                DueDate := DueDate + 1;
            Attempts += 1;
        end;
        exit(DueDate);
    end;

    local procedure IsNonWorkingDay(TargetDate: Date): Boolean
    var
        BaseCalendar: Record "Base Calendar";
        CustomizedCalendarChange: Record "Customized Calendar Change";
        CalendarManagement: Codeunit "Calendar Management";
    begin
        if Date2DWY(TargetDate, 1) > 5 then
            exit(true);
        if "Base Calendar Code" = '' then
            exit(false);
        if not BaseCalendar.Get("Base Calendar Code") then
            exit(false);
        CalendarManagement.SetSource(BaseCalendar, CustomizedCalendarChange);
        exit(CalendarManagement.IsNonworkingDay(TargetDate, CustomizedCalendarChange));
    end;
}
