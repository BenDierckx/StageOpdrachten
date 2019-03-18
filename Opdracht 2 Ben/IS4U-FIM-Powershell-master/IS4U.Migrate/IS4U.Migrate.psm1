<#
Copyright (C) 2016 by IS4U (info@is4u.be)

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
#Set-ResourceManagementClient -BaseAddress http://localhost:5725;
#endregion Lithnet

Function Start-Migration {
    Param(    
    )
}

Function Write-ToXmlFile {
    <#
    .SYNOPSIS
    Writes a MIM object to a xml-file
    
    .DESCRIPTION
    Writes an object to a xml-file,
    this will create a Lithnet type xml file
    This file can be used for Import-RmConfig to import in a new MIM setup
    
    .PARAMETER ObjectType
    Give the object type that will be searched in the MIM service and to be placed in a xml file
    
    .PARAMETER AnchorName
    Specify the anchor name when a different anchor is used

    .PARAMETER Target
    Specify if the xml that gets written comes from the source or the target MIM setup

    .EXAMPLE
    Write-ToXmlFile -ObjectType AttributeTypeDescription
    #>
    param (
        [Parameter(Mandatory=$True)]
        [String]
        $ObjectType,

        [Parameter(Mandatory=$True)]
        [string]
        [ValidateScript({("Source", "Destination") -contains $_})]
        $Target,

        [Parameter(Mandatory=$False)]
        [String]
        $AnchorName = "Name"
    )
    # Inititalization xml file
    $FileName = "configurationTemplate.xml"
    $XmlDoc = [System.Xml.XmlDocument] (Get-Content $FileName)
    $node = $XmlDoc.SelectSingleNode('//Operations')

    # Get all the objects from the MIM
    $AllAttrObjects = Search-Resources -Xpath "/$ObjectType" -ExpectedObjectType $ObjectType

    # Place object in XML file
    # Iterate over the array of PsCustomObjects from Search-Resources
    foreach($obj in $AllAttrObjects) {
        # Operation description
        $xmlElement = $XmlDoc.CreateElement("ResourceOperation")
        $XmlOperation = $node.AppendChild($xmlElement)
        $XmlOperation.SetAttribute("operation", "Add Update")
        $XmlOperation.SetAttribute("resourceType", $ObjectType)
        # Anchor description
        $xmlElement = $XmlDoc.CreateElement("AnchorAttributes")
        $XmlAnchors = $XmlOperation.AppendChild($xmlElement)
        $xmlElement = $XmlDoc.CreateElement("AnchorAttribute")
        $xmlElement.Set_InnerText($AnchorName)
        $XmlAnchors.AppendChild($xmlElement)
        # Attributes of the object
        $xmlEle = $XmlDoc.CreateElement("AttributeOperations")
        $XmlAttributes = $XmlOperation.AppendChild($xmlEle)
        # Get the PsCustomObject members from the MIM service without the hidden/extra members
        $objMembers = $obj.psobject.Members | Where-Object membertype -like 'noteproperty'
        # iterate over the PsCustomObject members and append them to the AttributeOperations element
        foreach ($member in $objMembers) {
            # ObjectType already gets used in the operation description so skip it
            if ($member.Name -eq "ObjectType") { continue }
            $xmlVarElement = $XmlDoc.CreateElement("AttributeOperation")
            $xmlVarElement.Set_InnerText($member.Value)
            $xmlVariable = $XmlAttributes.AppendChild($xmlVarElement)
            $xmlVariable.SetAttribute("Operation", "add") #Add of replace?
            $xmlVariable.SetAttribute("Name", $member.Name)
        }
    }
    # Save the xml in a seperate xml file 
    $XmlDoc.Save(".\IS4U.Migrate\$Target$ObjectType.xml")
    # Confirmation
    Write-Host "Written objects of $ObjectType"
    # Return the new xml 
    #[xml]$result = $XmlDoc | Select-Xml -XPath "//ResourceOperation[@resourceType='$ObjectType']"
    [xml]$result = [System.Xml.XmlDocument] (Get-Content ".\$Target$ObjectType.xml")
    return $result
}

Function Get-SchemaConfig {
    param (
        [Parameter(Mandatory=$true)]
        [string]
        [ValidateScript({("Source", "Destination") -contains $_})]
        $Target
    )
    # Write xml files and return the xml (of filepaths?) !!
    [xml]$xmlForAttributes = Write-ToXmlFile -ObjectType AttributeTypeDescription -Target $Target
    [xml]$xmlForObjects = Write-ToXmlFile -ObjectType ObjectTypeDescription -Target $Target
    [xml]$xmlForBindings = Write-ToXmlFile -ObjectType BindingDescription -Target $Target
    # configurationTemplate.xml as base file
    [xml]$schemaConfig = Get-Content configurationTemplate.xml
    # Add the returns of Write-ToXmlFile to $schemaConfig
    #aparte functie voor foreach?
    foreach($Node in $xmlForAttributes.'Lithnet.ResourceManagement.ConfigSync'.ChildNodes) {
        # Importnode($Node, $true): the $true means that argument 'Deep' is enabled
        # Deep makes sure the descendants of the node get copied aswell
        $schemaConfig.'Lithnet.ResourceManagement.ConfigSync'.Operations.AppendChild($schemaConfig.ImportNode($Node, $true))
    }
    foreach ($Node in $xmlForObjects.'Lithnet.ResourceManagement.ConfigSync'.ChildNodes) {
        $schemaConfig."Lithnet.ResourceManagement.ConfigSync".Operations.AppendChild($schemaConfig.ImportNode($Node, $true))
    }
    foreach ($Node in $xmlForBindings.'Lithnet.ResourceManagement.ConfigSync'.ChildNodes) {
        $schemaConfig."Lithnet.ResourceManagement.ConfigSync".Operations.AppendChild($schemaConfig.ImportNode($Node, $true))
    }
    $schemaConfig.Save("IS4U-FIM-Powershell-master\IS4U.Migrate\SchemaConfig$Target.xml")
    return $schemaConfig
    #[xml]$config = Get-Content SchemaConfig.xml
    #return $config
}

Function Get-PolicyConfig {
    Write-ToXmlFile -ObjectType ManagementPolicyRule
    #...?
}

Function Get-PortalConfig {
  # Check on objectTypes
  # $? = Search-Resources -Xpath "/?" -ExpectedObjectType ?
}

Function Write-ChangesToNewConfig {
# = New-Delta?
}

Function Compare-XmlFiles {
# Vergelijken van bron xml met target xml of andere file type
}

Function New-Delta {
# aanmaken van xml met de verschillen uit Compare-XmlFiles
}

Function Import-Delta {
    <#
    .SYNOPSIS
    Import a delta or more in a MIM-setup
    
    .DESCRIPTION
    Import the differences between the source MIM setup(s) and the target MIM setup(s) in the target 
    MIM setup
    This delta file(s) has to be send with the correct parameter
    
    .PARAMETER SourceConfigFilePath
    The path to a delta of a configuration xml file
    
    .PARAMETER SourceSeperateConfigFilePaths
    The path(s) to delta(s) of specific parts of a configuration in xml file(s)
    
    .EXAMPLE
    Import-Delta -DeltaConfigFilePath "./ConfigurationDelta.xml"
    #>
    
    param (
        [Parameter(Mandatory=$false)]
        [string]
        $DeltaConfigFilePath,

        [Parameter(Mandatory=$false)]
        [array]
        $DeltaSeperateConfigFilePaths
    )
    try{
        if ($DeltaConfigFilePath) {
            Import-RMConfig $DeltaConfigFilePath
        } elseif ($DeltaSeperateConfigFilePaths) {
            foreach($file in $DeltaSeperateConfigFilePaths){
                Import-RMConfig $file
            }
        } else {
            Write-Host "No config file(s) given, import canceled."
        }
    } Catch {
        Write-Host "Something went wrong, check config file paths and if they are available:"
        Write-Host "config file: $DeltaConfigFilePath"
        Write-Host "config files: $DeltaSeperateConfigFilePaths"
        Break
    }
}