table 50124 "NFB Tax Settlement Entry"
{
    Caption = 'NF-e Tax Settlement Entry';
    DataClassification = CustomerContent;
    DrillDownPageId = "NFB Tax Settlement Entries";
    LookupPageId = "NFB Tax Settlement Entries";

    fields
    {
        field(1; "Settlement No."; Code[20])
        {
            Caption = 'Settlement No.';
            TableRelation = "NFB Tax Settlement Header";
        }
        field(2; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(3; "Tax Type"; Enum "NFB Tax Type")
        {
            Caption = 'Tax Type';
        }
        field(4; "State Code"; Code[2])
        {
            Caption = 'UF';
        }
        field(5; "Source Doc. Type"; Enum "NFB Source Doc. Type")
        {
            Caption = 'Source Document Type';
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(8; "Source No."; Code[20])
        {
            Caption = 'Customer/Vendor No.';
        }
        field(10; "Base Amount"; Decimal)
        {
            Caption = 'Base Amount';
            AutoFormatType = 1;
        }
        field(11; "Output Tax"; Decimal)
        {
            Caption = 'Output Tax (Debits)';
            AutoFormatType = 1;
        }
        field(12; "Input Tax"; Decimal)
        {
            Caption = 'Input Tax (Credits)';
            AutoFormatType = 1;
        }
    }

    keys
    {
        key(PK; "Settlement No.", "Entry No.") { Clustered = true; }
        key(Tax; "Settlement No.", "Tax Type", "State Code") { SumIndexFields = "Output Tax", "Input Tax"; }
        key(Document; "Settlement No.", "Source Doc. Type", "Document No.", "Tax Type", "State Code") { }
    }

    procedure ShowDocument()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        case "Source Doc. Type" of
            "Source Doc. Type"::"Sales Invoice":
                if SalesInvoiceHeader.Get("Document No.") then
                    Page.Run(Page::"Posted Sales Invoice", SalesInvoiceHeader);
            "Source Doc. Type"::"Sales Cr. Memo":
                if SalesCrMemoHeader.Get("Document No.") then
                    Page.Run(Page::"Posted Sales Credit Memo", SalesCrMemoHeader);
            "Source Doc. Type"::"Purchase Invoice":
                if PurchInvHeader.Get("Document No.") then
                    Page.Run(Page::"Posted Purchase Invoice", PurchInvHeader);
            "Source Doc. Type"::"Purchase Cr. Memo":
                if PurchCrMemoHdr.Get("Document No.") then
                    Page.Run(Page::"Posted Purchase Credit Memo", PurchCrMemoHdr);
        end;
    end;
}
