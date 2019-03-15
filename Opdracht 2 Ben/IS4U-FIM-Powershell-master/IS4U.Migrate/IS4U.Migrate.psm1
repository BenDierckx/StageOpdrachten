<#
Copyright (C) 2015 by IS4U (info@is4u.be)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation version 3.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A full copy of the GNU General Public License can be found
here: http://opensource.org/licenses/gpl-3.0.
#>
Set-StrictMode -Version Latest

#region Lithnet
if(!(Get-Module -Name LithnetRMA))
{
Import-Module LithnetRMA;
}

Function Mirgate {
    # Parameter help description
    param(
		[Parameter(Mandatory=$True)]
		[string]
        $ObjectType,
        
        [Parameter(Mandatory=$True)]
        [string]
        [ValidateScript({("Source", "Destination") -contains $_})]
        $Target,
        
        [Parameter(Mandatory=$True)]
		[string]
		$AchorName = "Name"
    )

    $AllObjects = Search-Resources -Xpath "/$ObjectType" -ExpectedObjectType $ObjectType

    $FileName = "ConfigurationTemplate.xml"
    $XmlDoc = [System.Xml.XmlDocument] (Get-Content $FileName)
    $Node = $XmlDoc.SelectSingleNode('//Operations')

    foreach ($obj in $AllObjects) {
        $XmlElement = $XmlDoc.CreateElement("ResourceOperation")
        $XmlResourceOperation = $Node.AppendChild($XmlElement)
        $XmlResourceOperation.SetAttribute("Operation", "Add Update")
        $XmlResourceOperation.SetAttribute("ResourceType", $ObjectType)
        
        $XmlElement = $XmlDoc.CreateElement("AnchorAttributes")
        $XmlAnchorAttributes = $XmlOperation.AppendChild($XmlElement)
        $XmlElement = $XmlDoc.CreateElement("AnchorAttribute")
        $XmlElement.Set_InnerText($AchorName)
        $XmlAnchorAttributes.AppendChild($XmlElement)

        $XmlElement = $XmlDoc.CreateElement("AttributeOperations")
        $XmlAttributeOperations = $XmlOperation.AppendChild($XmlElement)
        
        $objMembers = $obj.PsObject.Members | Where-Object MemberType -Like 'NoteProperty'

        foreach ($member in $objMembers) {
            
        }
    }
}
Function Import-Descriptions {
    $Attributes = Search-Resources -Xpath "/AttributeTypeDescription" -ExpectedObjectType AttributeTypeDescription
    $Bindings = Search-Resources -Xpath "/BindingDescription" -ExpectedObjectType BindingDescription
    $Objects = Search-Resources -Xpath "/ObjectTypeDescription" -ExpectedObjectType ObjectTypeDescription
}

Function Get-SchemaConfig {
    #$FileName = "newObject.xml"
    #$File = [System.Xml.XmlDocument] (Get-Content $FileName)
}

Function Get-PortalConfig {

}

Function Get-PolicyConfig {
    
}

Function New-DeltaFile {

}