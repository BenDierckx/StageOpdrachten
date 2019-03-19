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
        # Target Name
        [Parameter(Mandatory=$False)]
        [String]
        $TargetName
    )

    Get-SchemaConfig -TargetName $TargetName
}

Function Write-ToXmlFile {
    <# Moet worden herschreven om het juiste object te lezen en de gepaste file te saven
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

    .EXAMPLE
    Write-ToXmlFile -ObjectType AttributeTypeDescription
    #>
    param (
        [Parameter(Mandatory=$True)]
        [String]
        $ObjectType,

        [Parameter(Mandatory=$false)]
        [String]
        $TargetName,

        [Parameter(Mandatory=$False)]
        [String]
        $AnchorName = "Name"
    )
    # Inititalization xml file
    $FileName = "configurationTemplate.xml"
    $XmlDoc = [System.Xml.XmlDocument] (Get-Content $FileName)
    $node = $XmlDoc.SelectSingleNode('//Operations')
    # Get all the objects from the MIM
    $AllObjects = Search-Resources -Xpath "/$ObjectType" -ExpectedObjectType $ObjectType

    # Place object in XML file
    # Iterate over the array of PsCustomObjects from Search-Resources
    foreach($obj in $AllObjects) {
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
            if ($member.Name -eq "usageKeyword") {
                foreach ($m in $member.Value) {
                    $xmlVarElement = $XmlDoc.CreateElement("AttributeOperation")
                    $xmlVarElement.Set_InnerText($m)
                    $xmlVariable = $XmlAttributes.AppendChild($xmlVarElement)
                    $xmlVariable.SetAttribute("operation", "add") # add because we don't want to replace the items 
                    $xmlVariable.SetAttribute("name", $member.Name)
                }
            }
            # Attributes that are read only do not get implemented in the xml file
            $illegalMembers = @("ObjectType", "CreatedTime", "Creator", "DeletedTime", "DetectedRulesList",
             "ExpectedRulesList", "ResourceTime")
            # Skip read only attributes and ObjectType (already used in ResourceOperation)
            if ($illegalMembers -contains $member.Name) { continue }
            # referencing purposes, no need in the attributes itself (Lithnet does this)
            if ($member.Name -eq "ObjectID") {
                # set the objectID of the object as the id of the xml node
                $XmlOperation.SetAttribute("id", $member.Value)
                continue # Import-RmConfig creates an objectID in the new setup
            }
            $xmlVarElement = $XmlDoc.CreateElement("AttributeOperation")
            $xmlVarElement.Set_InnerText($member.Value)
            $xmlVariable = $XmlAttributes.AppendChild($xmlVarElement)
            $xmlVariable.SetAttribute("operation", "replace") #Add of replace?
            $xmlVariable.SetAttribute("name", $member.Name)
            if ($member.Name -eq "BoundAttributeType" -or $member.Name -eq "BoundObjectType") {
                $xmlVariable.SetAttribute("type", "xmlref")
            }
        }
    }
    # Save the xml in a seperate xml file 
    $XmlDoc.Save(".\IS4U.Migrate\$ObjectType$TargetName.xml")
    # Confirmation
    Write-Host "Written objects of $ObjectType"
    # Return the new xml 
    #[xml]$result = $XmlDoc | Select-Xml -XPath "//ResourceOperation[@resourceType='$ObjectType']"
    #[xml]$result = [System.Xml.XmlDocument] (Get-Content ".\$ObjectType.xml")
    #return $result
}

Function Get-SchemaConfig {
    # Hierbij wordt alles in een xmlfile gestoken => herschrijven om naar een csv of .. te schrijven
    param(
        # Name of the target (source or destination)
        [Parameter(Mandatory=$False)]
        [String]
        $TargetName
    )
    # Write xml files and return the xml (of filepaths?) !!
    Write-ToXmlFile -ObjectType AttributeTypeDescription -TargetName $TargetName
    [xml]$xmlForAttributes = Get-Content ".\AttributeTypeDescription$TargetName.xml"
    Write-ToXmlFile -ObjectType ObjectTypeDescription  -TargetName $TargetName
    [xml]$xmlForObjects = Get-Content ".\ObjectTypeDescription$TargetName.xml"
    Write-ToXmlFile -ObjectType BindingDescription -TargetName $TargetName
    [xml]$xmlForBindings = Get-Content ".\BindingDescription$TargetName.xml"
    # configurationTemplate.xml as base file
    [xml]$schemaConfig = Get-Content configurationTemplate.xml
    # Add the returns of Write-ToXmlFile to $schemaConfig xml
    #aparte functie voor foreach?
    foreach($Node in $xmlForAttributes.SelectSingleNode('//Operations').ChildNodes) {
        # Importnode($Node, $true): the $true means that argument 'Deep' is enabled
        # Deep makes sure the descendants of the node get copied aswell
        $schemaConfig.SelectSingleNode('//Operations').AppendChild($schemaConfig.ImportNode($Node, $true))
    }
    foreach ($Node in $xmlForObjects.SelectSingleNode('//Operations').ChildNodes) {
        $schemaConfig.SelectSingleNode('//Operations').AppendChild($schemaConfig.ImportNode($Node, $true))
    }
    foreach ($Node in $xmlForBindings.SelectSingleNode('//Operations').ChildNodes) {
        $schemaConfig.SelectSingleNode('//Operations').AppendChild($schemaConfig.ImportNode($Node, $true))
    }
    $schemaConfig.Save("IS4U.Migrate\SchemaConfig$TargetName.xml")
    Write-Host "Schema configuration has been written to xml"
    #return $schemaConfig
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
# Te omslachtig om de 2 xml files te vergelijken => elke node vergelijken met alle nodes van andere xml
# Gaat ook te lang duren om alles dan te automatiseren en in 1 keer te laten verlopen
# Bij compare-object krijg je alleen maar 1 lijn terug, dus niet voldoende informatie over waar het in zit
    param (
        # Target
        [Parameter(Mandatory=$True)]
        [String]
        $TargetName
    )
    [xml]$sourceXml = Get-Content ".\SchemaConfig.xml"
    [xml]$targetXml = Get-Content ".\SchemaConfig$TargetName.xml"

    foreach ($SNode in $sourceXml.SelectNodes("//ResourceOperation")) {
        foreach ($TNode in $targetXml.SelectNodes("//ResourceOperation")) {
            if ($Tnode -eq $SNode) {
                Write-Host $TNode
            } else {
                Write-Host $SNode
            }
        }
    }
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
    if ($DeltaConfigFilePath) {
        Import-RMConfig $DeltaConfigFilePath -Preview -Verbose
    } elseif ($DeltaSeperateConfigFilePaths) {
        foreach($file in $DeltaSeperateConfigFilePaths){
            Import-RMConfig $file -Preview -Verbose
        }
    } else {
        Write-Host "No config file(s) given, import canceled."
    }
}