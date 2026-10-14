codeunit 50110 "NFB Create Document"
{
    // Runs the builder in its own Codeunit.Run so a failure after posting does not surface as a posting error.
    TableNo = "NFB Document Header";

    trigger OnRun()
    var
        NFBDocumentBuilder: Codeunit "NFB Document Builder";
    begin
        Rec."No." := NFBDocumentBuilder.CreateDocument(Rec."Source Doc. Type", Rec."Source Doc. No.");
    end;

    procedure TryCreate(SourceDocType: Enum "NFB Source Doc. Type"; SourceDocNo: Code[20])
    var
        TempNFBDocumentHeader: Record "NFB Document Header" temporary;
        NFBSetup: Record "NFB Setup";
    begin
        if not NFBSetup.Get() then
            exit;
        if not NFBSetup."Auto Create Document" then
            exit;
        TempNFBDocumentHeader."Source Doc. Type" := SourceDocType;
        TempNFBDocumentHeader."Source Doc. No." := SourceDocNo;
        if not Codeunit.Run(Codeunit::"NFB Create Document", TempNFBDocumentHeader) then
            if GuiAllowed() then
                Message(CouldNotCreateMsg, SourceDocType, SourceDocNo, GetLastErrorText());
    end;

    var
        CouldNotCreateMsg: Label 'The document was posted, but NF-e for %1 %2 could not be created: %3\Use the NF-e action on the posted document to create it.', Comment = '%1 = source type, %2 = source no., %3 = error';
}
