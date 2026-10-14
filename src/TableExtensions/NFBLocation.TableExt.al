tableextension 50126 "NFB Location" extends Location
{
    fields
    {
        field(50101; "NFB CNPJ"; Code[14])
        {
            Caption = 'CNPJ';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                NFBValidation: Codeunit "NFB Validation";
            begin
                "NFB CNPJ" := CopyStr(NFBValidation.OnlyDigits("NFB CNPJ"), 1, MaxStrLen("NFB CNPJ"));
                if "NFB CNPJ" <> '' then
                    NFBValidation.CheckCpfCnpj("NFB CNPJ");
            end;
        }
        field(50103; "NFB IE"; Code[14])
        {
            Caption = 'State Registration (IE)';
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
