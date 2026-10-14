table 50120 "NFB Document Event"
{
    Caption = 'NF-e Document Event';
    DataClassification = CustomerContent;
    LookupPageId = "NFB Document Events";
    DrillDownPageId = "NFB Document Events";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "NFB Document Header";
        }
        field(3; "Event Type"; Enum "NFB Event Type")
        {
            Caption = 'Event Type';
        }
        field(4; "Sequence No."; Integer)
        {
            Caption = 'Sequence No. (nSeqEvento)';
        }
        field(5; "Event Text"; Text[1000])
        {
            Caption = 'Justification / Correction';
        }
        field(6; Status; Option)
        {
            Caption = 'Status';
            OptionMembers = Pending,Registered,Rejected;
            OptionCaption = 'Pending,Registered,Rejected';
        }
        field(7; "Status Code"; Integer)
        {
            Caption = 'Status Code (cStat)';
        }
        field(8; "Status Reason"; Text[250])
        {
            Caption = 'Status Reason (xMotivo)';
        }
        field(9; "Protocol No."; Code[15])
        {
            Caption = 'Protocol No. (nProt)';
        }
        field(10; "Access Key"; Code[44])
        {
            Caption = 'Access Key';
        }
        field(11; "Created At"; DateTime)
        {
            Caption = 'Created At';
        }
        field(12; "Created By"; Code[50])
        {
            Caption = 'Created By';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(13; "Registered At"; DateTime)
        {
            Caption = 'Registered At';
        }
        field(14; "Provider Id"; Text[50])
        {
            Caption = 'Provider Id';
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Document; "Document No.", "Event Type", "Sequence No.") { }
        key(Status; Status) { }
    }

    trigger OnInsert()
    begin
        "Created At" := CurrentDateTime();
        "Created By" := CopyStr(UserId(), 1, MaxStrLen("Created By"));
    end;
}
