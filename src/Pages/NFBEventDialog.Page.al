page 50117 "NFB Event Dialog"
{
    PageType = StandardDialog;
    Caption = 'NF-e Event';

    layout
    {
        area(Content)
        {
            field(InstructionField; Instruction)
            {
                ApplicationArea = All;
                ShowCaption = false;
                Editable = false;
                MultiLine = true;
            }
            field(EventTextField; EventText)
            {
                ApplicationArea = All;
                Caption = 'Text';
                MultiLine = true;
                ToolTip = 'Specifies the justification or the correction. It must have between 15 and 1000 characters.';
            }
        }
    }

    var
        Instruction: Text;
        EventText: Text[1000];

    procedure SetInstruction(NewInstruction: Text)
    begin
        Instruction := NewInstruction;
    end;

    procedure GetEventText(): Text[1000]
    begin
        exit(EventText);
    end;
}
