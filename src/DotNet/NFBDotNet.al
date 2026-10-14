// .NET types used to validate the NF-e XML against the SEFAZ schemas (target OnPrem).
// Same declarations the BC test library uses in "Library - Verify XML Schema".
dotnet
{
    assembly("netstandard")
    {
        type("System.Xml.XmlDocument"; "NFBXmlDocument") { }
        type("System.Xml.XmlUrlResolver"; "NFBXmlUrlResolver") { }
        type("System.Xml.XmlTextReader"; "NFBXmlTextReader") { }
        type("System.Xml.Schema.XmlSchema"; "NFBXmlSchema") { }
        type("System.Xml.Schema.ValidationEventHandler"; "NFBValidationEventHandler") { }
    }
}
