report 50101 "NFB NF-e by Period"
{
    Caption = 'NF-e by Period';
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;
    DefaultRenderingLayout = NFeByPeriod;

    dataset
    {
        dataitem(Header; "NFB Document Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = Status, Series, Direction, "Operation Type";

            column(CompanyName; CompanyProperty.DisplayName()) { }
            column(FilterText; FilterText) { }
            column(DocumentNo; Header."No.") { }
            column(NFNo; NFNoText) { }
            column(Series; Format(Header.Series)) { }
            column(IssueDate; IssueDateText) { }
            column(Status; Format(Header.Status)) { }
            column(Direction; Format(Header.Direction)) { }
            column(CFOPText; CFOPText) { }
            column(RecipientName; Header."Recipient Name") { }
            column(RecipientDoc; Header."Recipient CPF/CNPJ") { }
            column(AccessKey; Header."Access Key") { }
            column(InvoiceAmount; FormatAmount(Header."Invoice Amount")) { }
            column(ICMSAmount; FormatAmount(Header."ICMS Amount")) { }
            column(STAmount; FormatAmount(Header."ICMS ST Amount")) { }
            column(IPIAmount; FormatAmount(Header."IPI Amount")) { }
            column(PISAmount; FormatAmount(Header."PIS Amount")) { }
            column(COFINSAmount; FormatAmount(Header."COFINS Amount")) { }
            column(IBSAmount; FormatAmount(Header."IBS UF Amount" + Header."IBS Mun. Amount")) { }
            column(CBSAmount; FormatAmount(Header."CBS Amount")) { }
            column(InvoiceAmountNum; Header."Invoice Amount") { }
            column(ICMSAmountNum; Header."ICMS Amount") { }
            column(STAmountNum; Header."ICMS ST Amount") { }
            column(IPIAmountNum; Header."IPI Amount") { }
            column(PISAmountNum; Header."PIS Amount") { }
            column(COFINSAmountNum; Header."COFINS Amount") { }
            column(IBSAmountNum; Header."IBS UF Amount" + Header."IBS Mun. Amount") { }
            column(CBSAmountNum; Header."CBS Amount") { }

            trigger OnPreDataItem()
            begin
                if (StartDate <> 0D) or (EndDate <> 0D) then
                    Header.SetRange("Posting Date", StartDate, EndDate);
                FilterText := Header.GetFilters();
            end;

            trigger OnAfterGetRecord()
            var
                NFBDocumentLine: Record "NFB Document Line";
            begin
                NFNoText := '';
                if Header."NF No." <> 0 then
                    NFNoText := Format(Header."NF No.");
                if Header."Issue DateTime" <> 0DT then
                    IssueDateText := Format(DT2Date(Header."Issue DateTime"), 0, '<Day,2>/<Month,2>/<Year4>')
                else
                    IssueDateText := Format(Header."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>');
                CFOPText := '';
                NFBDocumentLine.SetCurrentKey("Document No.", "Item Seq.");
                NFBDocumentLine.SetRange("Document No.", Header."No.");
                if NFBDocumentLine.FindFirst() then
                    CFOPText := NFBDocumentLine.CFOP;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                group(Period)
                {
                    Caption = 'Period';
                    field(StartDateField; StartDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Start Date';
                        ToolTip = 'First posting date of the NF-e to list.';
                    }
                    field(EndDateField; EndDate)
                    {
                        ApplicationArea = All;
                        Caption = 'End Date';
                        ToolTip = 'Last posting date of the NF-e to list.';
                    }
                }
            }
        }
    }

    rendering
    {
        layout(NFeByPeriod)
        {
            Type = RDLC;
            LayoutFile = './src/Reports/Layouts/NFBNFeByPeriod.rdlc';
            Caption = 'NF-e by period (landscape)';
        }
    }

    var
        NFBXMLBuilder: Codeunit "NFB XML Builder";
        StartDate: Date;
        EndDate: Date;
        FilterText: Text;
        NFNoText: Text;
        IssueDateText: Text;
        CFOPText: Text;

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
