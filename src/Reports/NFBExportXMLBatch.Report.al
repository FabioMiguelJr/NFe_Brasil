report 50102 "NFB Export XML Batch"
{
    Caption = 'Export NF-e XML (ZIP)';
    ApplicationArea = All;
    UsageCategory = Tasks;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Header; "NFB Document Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = Status, Series, Direction;

            trigger OnPreDataItem()
            var
                NFBFileMgt: Codeunit "NFB File Mgt";
            begin
                if (StartDate <> 0D) or (EndDate <> 0D) then
                    Header.SetRange("Posting Date", StartDate, EndDate);
                NFBFileMgt.ExportZip(Header, GetZipFileName(), true);
                CurrReport.Break();
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
                        ToolTip = 'First posting date of the NF-e to export.';
                    }
                    field(EndDateField; EndDate)
                    {
                        ApplicationArea = All;
                        Caption = 'End Date';
                        ToolTip = 'Last posting date of the NF-e to export.';
                    }
                }
            }
        }
    }

    var
        StartDate: Date;
        EndDate: Date;
        ZipFileNameTxt: Label 'nfe-xml-%1.zip', Locked = true, Comment = '%1 = period or date';

    local procedure GetZipFileName(): Text
    begin
        if (StartDate <> 0D) and (EndDate <> 0D) then
            exit(StrSubstNo(ZipFileNameTxt, Format(StartDate, 0, '<Year4><Month,2><Day,2>') + '-' + Format(EndDate, 0, '<Year4><Month,2><Day,2>')));
        exit(StrSubstNo(ZipFileNameTxt, Format(Today(), 0, '<Year4><Month,2><Day,2>')));
    end;
}
