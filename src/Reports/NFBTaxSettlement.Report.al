report 50103 "NFB Tax Settlement"
{
    Caption = 'NF-e Tax Settlement';
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;
    DefaultRenderingLayout = TaxSettlement;

    dataset
    {
        dataitem(Header; "NFB Tax Settlement Header")
        {
            DataItemTableView = sorting("Starting Date");
            RequestFilterFields = "No.", "Starting Date", Status;
            PrintOnlyIfDetail = true;

            column(CompanyName; CompanyProperty.DisplayName()) { }
            column(FilterText; FilterText) { }
            dataitem(Line; "NFB Tax Settlement Line")
            {
                DataItemLink = "Settlement No." = field("No.");
                DataItemTableView = sorting("Settlement No.", "Tax Type", "State Code");

                column(SettlementNo; Header."No.") { }
                column(Period; Format(Header."Starting Date", 0, '<Month,2>/<Year4>')) { }
                column(SettlementStatus; Format(Header.Status)) { }
                column(TaxType; Format(Line."Tax Type")) { }
                column(StateCode; Line."State Code") { }
                column(OutputTax; FormatAmount(Line."Output Tax")) { }
                column(InputTax; FormatAmount(Line."Input Tax")) { }
                column(OtherDebits; FormatAmount(Line."Other Debits")) { }
                column(OtherCredits; FormatAmount(Line."Other Credits")) { }
                column(PreviousCredit; FormatAmount(Line."Previous Credit Balance")) { }
                column(AmountPayable; FormatAmount(Line."Amount Payable")) { }
                column(CreditCarriedForward; FormatAmount(Line."Credit Carried Forward")) { }
                column(GuideType; Format(Line."Guide Type")) { }
                column(RevenueCode; Line."Revenue Code") { }
                column(VendorNo; Line."Vendor No.") { }
                column(DueDate; DueDateText) { }
                column(AmountPayableNum; Line."Amount Payable") { }
                column(CreditCarriedForwardNum; Line."Credit Carried Forward") { }

                trigger OnAfterGetRecord()
                begin
                    DueDateText := '';
                    if Line."Due Date" <> 0D then
                        DueDateText := Format(Line."Due Date", 0, '<Day,2>/<Month,2>/<Year4>');
                end;
            }

            trigger OnPreDataItem()
            begin
                FilterText := Header.GetFilters();
            end;
        }
    }

    rendering
    {
        layout(TaxSettlement)
        {
            Type = RDLC;
            LayoutFile = './src/Reports/Layouts/NFBTaxSettlement.rdlc';
            Caption = 'Tax settlement by period (landscape)';
        }
    }

    var
        NFBXMLBuilder: Codeunit "NFB XML Builder";
        FilterText: Text;
        DueDateText: Text;

    /// <summary>
    /// Brazilian number format (1.234,56), independent of the user's regional settings.
    /// </summary>
    local procedure FormatAmount(Value: Decimal): Text
    var
        Plain: Text;
        IntegerPart: Text;
        Grouped: Text;
        Sign: Text;
        DotPos: Integer;
        I: Integer;
    begin
        Plain := NFBXMLBuilder.FormatDec(Value, 2, 2);
        if CopyStr(Plain, 1, 1) = '-' then begin
            Sign := '-';
            Plain := CopyStr(Plain, 2);
        end;
        DotPos := StrPos(Plain, '.');
        IntegerPart := CopyStr(Plain, 1, DotPos - 1);
        for I := 1 to StrLen(IntegerPart) do begin
            if (I > 1) and ((StrLen(IntegerPart) - I + 1) mod 3 = 0) then
                Grouped += '.';
            Grouped += CopyStr(IntegerPart, I, 1);
        end;
        exit(Sign + Grouped + ',' + CopyStr(Plain, DotPos + 1));
    end;
}
