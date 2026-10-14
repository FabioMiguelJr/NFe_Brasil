tableextension 50101 "NFB Customer" extends Customer
{
    fields
    {
        field(50108; "NFB Person Type"; Enum "NFB Person Type")
        {
            Caption = 'Person Type';
            DataClassification = CustomerContent;
        }
        field(50101; "NFB CPF/CNPJ"; Code[14])
        {
            Caption = 'CPF/CNPJ';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                NFBValidation: Codeunit "NFB Validation";
            begin
                "NFB CPF/CNPJ" := CopyStr(NFBValidation.OnlyDigits("NFB CPF/CNPJ"), 1, MaxStrLen("NFB CPF/CNPJ"));
                if "NFB CPF/CNPJ" <> '' then
                    NFBValidation.CheckCpfCnpj("NFB CPF/CNPJ");
            end;
        }
        field(50102; "NFB IE Indicator"; Enum "NFB IE Indicator")
        {
            Caption = 'IE Indicator (indIEDest)';
            DataClassification = CustomerContent;
            InitValue = "Non-Contributor";
        }
        field(50103; "NFB IE"; Code[14])
        {
            Caption = 'State Registration (IE)';
            DataClassification = CustomerContent;
        }
        field(50104; "NFB Final Consumer"; Boolean)
        {
            Caption = 'Final Consumer';
            DataClassification = CustomerContent;
        }
        field(50105; "NFB SUFRAMA"; Code[9])
        {
            Caption = 'SUFRAMA Registration';
            DataClassification = CustomerContent;
        }
        field(50106; "NFB XML E-Mail"; Text[80])
        {
            Caption = 'NF-e XML E-Mail';
            DataClassification = CustomerContent;
            ExtendedDatatype = EMail;
        }
        field(50107; "NFB Foreign Id"; Code[20])
        {
            Caption = 'Foreign Id (idEstrangeiro)';
            DataClassification = CustomerContent;
        }
        field(50110; "NFB Municipality Code"; Code[7])
        {
            Caption = 'Municipality (IBGE)';
            DataClassification = CustomerContent;
            TableRelation = "NFB Municipality";

            trigger OnValidate()
            var
                NFBMunicipality: Record "NFB Municipality";
            begin
                if "NFB Municipality Code" = '' then
                    exit;
                NFBMunicipality.Get("NFB Municipality Code");
                "NFB UF" := NFBMunicipality.UF;
                    City := CopyStr(NFBMunicipality.Name, 1, MaxStrLen(City));
            end;
        }
        field(50111; "NFB UF"; Code[2])
        {
            Caption = 'State (UF)';
            DataClassification = CustomerContent;
        }
        field(50112; "NFB Address No."; Text[60])
        {
            Caption = 'Address Number';
            DataClassification = CustomerContent;
        }
        field(50113; "NFB District"; Text[60])
        {
            Caption = 'District (Bairro)';
            DataClassification = CustomerContent;
        }
    }
}
