pageextension 50230 "NFB Transfer Order" extends "Transfer Order"
{
    layout
    {
        addlast(General)
        {
            group(NFBFiscal)
            {
                Caption = 'NF-e';
                field("NFB Operation Type"; Rec."NFB Operation Type") { ApplicationArea = All; }
                field("NFB Nature of Operation"; Rec."NFB Nature of Operation") { ApplicationArea = All; }
                field("NFB Purpose"; Rec."NFB Purpose") { ApplicationArea = All; }
                field("NFB Freight Mode"; Rec."NFB Freight Mode") { ApplicationArea = All; }
                field("NFB Referenced Key"; Rec."NFB Referenced Key") { ApplicationArea = All; }
                field("NFB Additional Info"; Rec."NFB Additional Info") { ApplicationArea = All; }
            }
        }
    }
}
