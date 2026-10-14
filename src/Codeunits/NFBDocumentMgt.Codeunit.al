codeunit 50209 "NFB Document Mgt"
{
    var
        ValidationFailedErr: Label 'NF-e %1 has %2 validation error(s). Fix them and validate again.', Comment = '%1 = document no., %2 = error count';
        NoSeriesMissingErr: Label 'NF-e series %1 (model %2) has no number series.', Comment = '%1 = series, %2 = model';
        ValidatedMsg: Label 'NF-e %1 is valid. Number %2, access key %3.', Comment = '%1 = document no., %2 = nNF, %3 = access key';

    /// <summary>
    /// Validates the NF-e and, when valid, reserves its number (nNF), generates cNF and the access key and sets the status to Validated.
    /// </summary>
    procedure ValidateDocument(var NFBDocumentHeader: Record "NFB Document Header"; ShowMessages: Boolean): Boolean
    var
        TempErrorMessage: Record "Error Message" temporary;
        NFBValidation: Codeunit "NFB Validation";
        NFBDocumentBuilder: Codeunit "NFB Document Builder";
    begin
        NFBDocumentHeader.TestStatusOpen();
        NFBDocumentBuilder.UpdateTotals(NFBDocumentHeader);

        if not NFBValidation.ValidateDocument(NFBDocumentHeader, TempErrorMessage) then begin
            NFBDocumentHeader."Validation Errors" := TempErrorMessage.Count();
            NFBDocumentHeader.Modify();
            if ShowMessages then begin
                Commit();
                TempErrorMessage.ShowErrorMessages(false);
                Error(ValidationFailedErr, NFBDocumentHeader."No.", NFBDocumentHeader."Validation Errors");
            end;
            exit(false);
        end;

        NFBDocumentHeader."Validation Errors" := 0;
        AssignNumber(NFBDocumentHeader);
        if NFBDocumentHeader.Status = NFBDocumentHeader.Status::Draft then
            NFBDocumentHeader.Status := NFBDocumentHeader.Status::Validated;
        NFBDocumentHeader.Modify();
        if ShowMessages then
            Message(ValidatedMsg, NFBDocumentHeader."No.", NFBDocumentHeader."NF No.", NFBDocumentHeader."Access Key");
        exit(true);
    end;

    procedure AssignNumber(var NFBDocumentHeader: Record "NFB Document Header")
    var
        NFBSeries: Record "NFB Series";
        NFBAccessKeyMgt: Codeunit "NFB Access Key Mgt";
        NoSeries: Codeunit "No. Series";
        NextNo: Code[20];
    begin
        // The number is kept once assigned: a rejected NF-e is corrected and sent again with the same number.
        if NFBDocumentHeader."NF No." = 0 then begin
            NFBSeries.Get(NFBDocumentHeader.Model, NFBDocumentHeader.Series);
            NFBSeries.TestField(Blocked, false);
            if NFBSeries."No. Series" = '' then
                Error(NoSeriesMissingErr, NFBDocumentHeader.Series, NFBDocumentHeader.Model);
            NextNo := NoSeries.GetNextNo(NFBSeries."No. Series", NFBDocumentHeader."Posting Date");
            Evaluate(NFBDocumentHeader."NF No.", NextNo);
            NFBDocumentHeader."Numeric Code" := NFBAccessKeyMgt.GenerateNumericCode(NFBDocumentHeader."NF No.");
        end;

        NFBDocumentHeader."Access Key" := NFBAccessKeyMgt.BuildAccessKey(
            NFBDocumentHeader."Issuer UF Code", DT2Date(NFBDocumentHeader."Issue DateTime"), NFBDocumentHeader."Issuer CNPJ",
            NFBDocumentHeader.Model, NFBDocumentHeader.Series, NFBDocumentHeader."NF No.", NFBDocumentHeader."Emission Type",
            NFBDocumentHeader."Numeric Code");
        Evaluate(NFBDocumentHeader."Check Digit", CopyStr(NFBDocumentHeader."Access Key", 44, 1));
    end;

    procedure OpenSourceDocument(NFBDocumentHeader: Record "NFB Document Header")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        TransferShipmentHeader: Record "Transfer Shipment Header";
    begin
        case NFBDocumentHeader."Source Doc. Type" of
            NFBDocumentHeader."Source Doc. Type"::"Sales Invoice":
                begin
                    SalesInvoiceHeader.Get(NFBDocumentHeader."Source Doc. No.");
                    Page.Run(Page::"Posted Sales Invoice", SalesInvoiceHeader);
                end;
            NFBDocumentHeader."Source Doc. Type"::"Sales Cr. Memo":
                begin
                    SalesCrMemoHeader.Get(NFBDocumentHeader."Source Doc. No.");
                    Page.Run(Page::"Posted Sales Credit Memo", SalesCrMemoHeader);
                end;
            NFBDocumentHeader."Source Doc. Type"::"Purchase Invoice":
                begin
                    PurchInvHeader.Get(NFBDocumentHeader."Source Doc. No.");
                    Page.Run(Page::"Posted Purchase Invoice", PurchInvHeader);
                end;
            NFBDocumentHeader."Source Doc. Type"::"Purchase Cr. Memo":
                begin
                    PurchCrMemoHdr.Get(NFBDocumentHeader."Source Doc. No.");
                    Page.Run(Page::"Posted Purchase Credit Memo", PurchCrMemoHdr);
                end;
            NFBDocumentHeader."Source Doc. Type"::"Transfer Shipment":
                begin
                    TransferShipmentHeader.Get(NFBDocumentHeader."Source Doc. No.");
                    Page.Run(Page::"Posted Transfer Shipment", TransferShipmentHeader);
                end;
        end;
    end;

    procedure CreateAndOpen(SourceDocType: Enum "NFB Source Doc. Type"; SourceDocNo: Code[20])
    var
        NFBDocumentHeader: Record "NFB Document Header";
        NFBDocumentBuilder: Codeunit "NFB Document Builder";
    begin
        NFBDocumentHeader.Get(NFBDocumentBuilder.CreateDocument(SourceDocType, SourceDocNo));
        Page.Run(Page::"NFB Document Card", NFBDocumentHeader);
    end;

    procedure OpenForSource(SourceDocType: Enum "NFB Source Doc. Type"; SourceDocNo: Code[20])
    var
        NFBDocumentHeader: Record "NFB Document Header";
    begin
        NFBDocumentHeader.SetRange("Source Doc. Type", SourceDocType);
        NFBDocumentHeader.SetRange("Source Doc. No.", SourceDocNo);
        Page.Run(Page::"NFB Document List", NFBDocumentHeader);
    end;
}
