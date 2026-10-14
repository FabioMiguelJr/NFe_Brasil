table 50121 "NFB Tax Settlement Header"
{
    Caption = 'NF-e Tax Settlement';
    DataClassification = CustomerContent;
    DrillDownPageId = "NFB Tax Settlements";
    LookupPageId = "NFB Tax Settlements";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            ToolTip = 'Specifies the month of the settlement. Any date of the month can be entered; it is moved to the first day.';

            trigger OnValidate()
            begin
                TestStatusOpen();
                if "Starting Date" = 0D then begin
                    "Ending Date" := 0D;
                    exit;
                end;
                "Starting Date" := CalcDate('<-CM>', "Starting Date");
                "Ending Date" := CalcDate('<CM>', "Starting Date");
                "Posting Date" := "Ending Date";
                Description := CopyStr(StrSubstNo(DescriptionTxt, Format("Starting Date", 0, '<Month,2>/<Year4>')), 1, MaxStrLen(Description));
                "Calculated At" := 0DT;
            end;
        }
        field(4; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            Editable = false;
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the date of the G/L entries that clear the tax accounts and of the payables to the tax authorities.';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(6; Status; Enum "NFB Settlement Status")
        {
            Caption = 'Status';
            Editable = false;
        }
        field(7; "Calculated At"; DateTime)
        {
            Caption = 'Calculated At';
            Editable = false;
        }
        field(8; "Posted At"; DateTime)
        {
            Caption = 'Posted At';
            Editable = false;
        }
        field(9; "Posted By"; Code[50])
        {
            Caption = 'Posted By';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(10; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(20; "Total Payable"; Decimal)
        {
            Caption = 'Total Payable';
            AutoFormatType = 1;
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("NFB Tax Settlement Line"."Amount Payable" where("Settlement No." = field("No.")));
        }
        field(21; "Total Credit Carried Forward"; Decimal)
        {
            Caption = 'Total Credit Carried Forward';
            AutoFormatType = 1;
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("NFB Tax Settlement Line"."Credit Carried Forward" where("Settlement No." = field("No.")));
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(Period; "Starting Date") { }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, "Starting Date", Status) { }
    }

    var
        DescriptionTxt: Label 'Tax settlement %1', Comment = '%1 = month/year';

    trigger OnInsert()
    var
        NFBSetup: Record "NFB Setup";
        NoSeries: Codeunit "No. Series";
    begin
        if "No." = '' then begin
            NFBSetup.GetRecordOnce();
            NFBSetup.TestField("Tax Settlement Nos.");
            "No. Series" := NFBSetup."Tax Settlement Nos.";
            "No." := NoSeries.GetNextNo("No. Series");
        end;
    end;

    trigger OnDelete()
    var
        NFBTaxSettlementLine: Record "NFB Tax Settlement Line";
        NFBTaxSettlementEntry: Record "NFB Tax Settlement Entry";
    begin
        TestStatusOpen();
        NFBTaxSettlementLine.SetRange("Settlement No.", "No.");
        NFBTaxSettlementLine.DeleteAll();
        NFBTaxSettlementEntry.SetRange("Settlement No.", "No.");
        NFBTaxSettlementEntry.DeleteAll();
    end;

    procedure TestStatusOpen()
    begin
        TestField(Status, Status::Open);
    end;
}
