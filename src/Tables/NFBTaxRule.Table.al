table 50206 "NFB Tax Rule"
{
    Caption = 'NF-e Tax Rule';
    DataClassification = CustomerContent;
    DrillDownPageId = "NFB Tax Rules";
    LookupPageId = "NFB Tax Rules";

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        // Matching criteria. A blank value matches anything; the rule with most filled criteria wins.
        field(10; "Operation Type"; Code[20])
        {
            Caption = 'Operation Type';
            TableRelation = "NFB Operation Type";
        }
        field(11; "Tax Group"; Code[20])
        {
            Caption = 'Item Tax Group';
        }
        field(12; Destination; Option)
        {
            Caption = 'Destination';
            OptionMembers = " ",Internal,Interstate,Exterior;
            OptionCaption = ' ,Internal,Interstate,Exterior';
        }
        field(13; "IE Indicator"; Option)
        {
            Caption = 'Recipient IE Indicator';
            OptionMembers = " ",Contributor,Exempt,"Non-Contributor";
            OptionCaption = ' ,Contributor,Exempt,Non-Contributor';
        }
        field(14; "Final Consumer"; Option)
        {
            Caption = 'Final Consumer';
            OptionMembers = " ",Yes,No;
            OptionCaption = ' ,Yes,No';
        }
        field(15; "Destination UF"; Code[2])
        {
            Caption = 'Destination State (UF)';
        }
        // Results
        field(20; CFOP; Code[4])
        {
            Caption = 'CFOP';
            TableRelation = "NFB CFOP";
        }
        field(30; "ICMS CST"; Code[3])
        {
            Caption = 'ICMS CST';
            Numeric = true;
        }
        field(31; "ICMS %"; Decimal)
        {
            Caption = 'ICMS %';
            DecimalPlaces = 0 : 4;
        }
        field(32; "ICMS Base Reduction %"; Decimal)
        {
            Caption = 'ICMS Base Reduction %';
            DecimalPlaces = 0 : 4;
            MinValue = 0;
            MaxValue = 100;
        }
        field(33; "FCP %"; Decimal)
        {
            Caption = 'FCP %';
            DecimalPlaces = 0 : 4;
        }
        field(34; "ICMS ST MVA %"; Decimal)
        {
            Caption = 'ICMS ST MVA %';
            DecimalPlaces = 0 : 4;
        }
        field(35; "ICMS ST Internal %"; Decimal)
        {
            Caption = 'ICMS ST Internal Rate %';
            DecimalPlaces = 0 : 4;
        }
        field(36; "ICMS ST Base Reduction %"; Decimal)
        {
            Caption = 'ICMS ST Base Reduction %';
            DecimalPlaces = 0 : 4;
            MinValue = 0;
            MaxValue = 100;
        }
        field(37; "FCP ST %"; Decimal)
        {
            Caption = 'FCP ST %';
            DecimalPlaces = 0 : 4;
        }
        field(38; "DIFAL Internal Dest. %"; Decimal)
        {
            Caption = 'DIFAL Destination Internal Rate %';
            DecimalPlaces = 0 : 4;
        }
        field(39; "FCP Dest. %"; Decimal)
        {
            Caption = 'FCP Destination %';
            DecimalPlaces = 0 : 4;
        }
        field(40; "IPI CST"; Code[2])
        {
            Caption = 'IPI CST';
            Numeric = true;
        }
        field(41; "IPI %"; Decimal)
        {
            Caption = 'IPI % (blank uses NCM)';
            DecimalPlaces = 0 : 4;
        }
        field(42; "IPI Enq. Code"; Code[3])
        {
            Caption = 'IPI Framework Code (cEnq)';
            InitValue = '999';
        }
        field(43; "Use NCM IPI %"; Boolean)
        {
            Caption = 'Use NCM IPI %';
            InitValue = true;
        }
        field(50; "PIS CST"; Code[2])
        {
            Caption = 'PIS CST';
            Numeric = true;
        }
        field(51; "PIS %"; Decimal)
        {
            Caption = 'PIS %';
            DecimalPlaces = 0 : 4;
        }
        field(52; "COFINS CST"; Code[2])
        {
            Caption = 'COFINS CST';
            Numeric = true;
        }
        field(53; "COFINS %"; Decimal)
        {
            Caption = 'COFINS %';
            DecimalPlaces = 0 : 4;
        }
        field(60; "IBS/CBS CST"; Code[3])
        {
            Caption = 'IBS/CBS CST';
            Numeric = true;
        }
        field(61; cClassTrib; Code[6])
        {
            Caption = 'cClassTrib';
            TableRelation = "NFB cClassTrib";
        }
        field(62; "IBS UF %"; Decimal)
        {
            Caption = 'IBS State %';
            DecimalPlaces = 0 : 4;
        }
        field(63; "IBS Mun. %"; Decimal)
        {
            Caption = 'IBS Municipality %';
            DecimalPlaces = 0 : 4;
        }
        field(64; "CBS %"; Decimal)
        {
            Caption = 'CBS %';
            DecimalPlaces = 0 : 4;
        }
        field(70; "Additional Info"; Text[250])
        {
            Caption = 'Legal Text for Additional Info';
        }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
        key(Match; "Operation Type", "Tax Group", Destination) { }
    }

    procedure Specificity(): Integer
    var
        Score: Integer;
    begin
        if "Operation Type" <> '' then
            Score += 16;
        if "Tax Group" <> '' then
            Score += 8;
        if "Destination UF" <> '' then
            Score += 4;
        if Destination <> Destination::" " then
            Score += 2;
        if "IE Indicator" <> "IE Indicator"::" " then
            Score += 1;
        if "Final Consumer" <> "Final Consumer"::" " then
            Score += 1;
        exit(Score);
    end;
}
