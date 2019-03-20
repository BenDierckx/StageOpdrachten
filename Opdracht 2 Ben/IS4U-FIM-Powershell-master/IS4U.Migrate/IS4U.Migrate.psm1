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
    param(
        # Source?
        [Parameter(Mandatory=$False)]
        [Bool]
        $SourceOfMIMSetup = $False
    )
    if ($SourceOfMIMSetup) {
        Get-SchemaConfig -Source $true
        Get-PortalConfig -Source $true
        Get-PolicyConfig -Source $true
    } else {
        [System.Collections.ArrayList]$SourceObjects = Get-AllObjectsFromCsvs
        [System.Collections.ArrayList]$DestinationObjects = Get-AllObjectsFromSetup
        $deltaObjects = Compare-Objects -ObjsSource $SourceObjects -ObjsDestination $DestinationObjects
        Write-ToXmlFile -DifferenceObjects $deltaObjects ## to do
        $delta = "ConfigurationDelta.xml" ## to do
        Import-Delta -DeltaConfigFilePath $delta 
    }
    #SOURCE
    # Get the schema => Get-SchemaConfig -SourceSchema $True + Get-...Csv + Get-...csv     +-V
    # bring csv's to destination server     V
    #DESTINATION
    # Use csvs that exist       V
    # Get the schemas from the to be updated setup => Get-schemaConfig + Get-....   +- V
    # Csv to array => Get-AllObjectsFromCsvs        V
    # compare arrays => Compare-Objects -ObjsSource $DevObjArray -ObjsDestination $ProdObjArray     +-V
    # Write differences to xml => Write-ToXml       +-V
    # Import-Delta -DeltaConfigFilePath $createdxml.xml     V
}

Function Get-AllObjectsFromSetup {
    $DestinationObjects = [System.Collections.ArrayList]@()
    $schema = Get-SchemaConfig
    $DestinationObjects.AddRange($schema)
    $policy = Get-PolicyConfig
    $DestinationObjects.AddRange($policy)
    $portal = Get-PortalConfig
    $DestinationObjects.AddRange($portal)
    return $DestinationObjects
}

Function Get-AllObjectsFromCsvs {
    [System.Collections.ArrayList] $global:SourceObjects = @()
        if (Test-Path -Path "CsvConfigAttributes.csv" -and Test-Path -Path "CsvConfigBindings.csv" -and Test-Path "CsvConfigObjectTypes.csv") {
            [System.Collections.ArrayList] $SourceSchemaObjects = @()
            $Attrs = Get-ObjectsFromCsv -CsvFilePath "CsvConfigAttributes.csv"
            $SourceSchemaObjects.AddRange($Attrs)
            $Objs = Get-ObjectsFromCsv -CsvFilePath "CsvConfigObjectTypes.csv"
            $SourceSchemaObjects.AddRange($Objs)
            $Bindings = Get-ObjectsFromCsv -CsvFilePath "CsvConfigBindings.csv"
            $SourceSchemaObjects.AddRange($Bindings)
            $global:SourceObjects.AddRange($SourceSchemaObjects)
        } else {
            Write-Host "No correct csv files found for Schema configuration"
            $answer = ""
            while ($answer -ne "y") {
                $answer = Read-Host -Prompt "Continue?[y/n]"
                if ($answer -eq "n") {
                    break
                }
            }
        }

        if (Test-Path -Path "CsvConfigPolicies.csv") {
          $SourcePolicyObjects = Get-ObjectsFromCsv -CsvFilePath "CsvConfigPolicies.csv"  
          $global:SourceObjects.AddRange($SourcePolicyObjects)
        } else {
            Write-Host "No correct csv file found for Policy management configuration"
            $answer = ""
            while ($answer -ne "y") {
                $answer = Read-Host -Prompt "Continue?[y/n]"
                if ($answer -eq "n") {
                    break
                }
            }
        }

        if (Test-Path -Path "CsvConfigPortals.csv") {
            $SourcePortalObjects = Get-ObjectsFromCsv -CsvFilePath "CsvConfigPolicies.csv"
            $global:SourceObjects.AddRange($SourcePortalObjects)    
        } else {
            Write-Host "No correct csv file found for Portal configuration"
            $answer = ""
            while ($answer -ne "y") {
                $answer = Read-Host -Prompt "Continue?[y/n]"
                if ($answer -eq "n") {
                    break
                }
            }
        }
    return $SourceObjects
}

Function Get-SchemaConfig {
    param (
        [Parameter(Mandatory=$False)]
        [Bool]
        $Source = $False
    )
    $attrs = Get-ObjectsFromConfig -ObjectType "AttributeTypeDescription"
    $objs = Get-ObjectsFromConfig -ObjectType ObjectTypeDescription
    $bindings = Get-ObjectsFromConfig -ObjectType BindingDescription
    $schema = [System.Collections.ArrayList] @()
    $schema.AddRange($attrs)
    $schema.AddRange($objs)
    $schema.AddRange($bindings)
    if ($Source) {
        Write-ToCsv -Objects $schema -CsvName Schema
    }
    return $schema
}

Function Get-PolicyConfig {
    param(
        [Parameter(Mandatory=$False)]
        [Bool]
        $Source = $False
    )
    $mgmntPolicies = Get-ObjectsFromConfig -ObjectType ManagementPolicyRule
    $sets = Get-ObjectsFromConfig -ObjectType Set
    $workflowDef = Get-ObjectsFromConfig -ObjectType WorkflowDefinition
    $emailtmplt = Get-ObjectsFromConfig -ObjectType EmailTemplate
    $filterscope = Get-ObjectsFromConfig -ObjectType FilterScope
    $activityInfo = Get-ObjectsFromConfig -ObjectType ActivityInformationConfiguration
    $funct = Get-ObjectsFromConfig -ObjectType Function
    $syncRule = Get-ObjectsFromConfig -ObjectType SynchronizationRule
    $syncFilter = Get-ObjectsFromConfig -ObjectType SynchronizationFilter
    if ($Source) {
        Write-ToCsv -Objects $mgmntPolicies -CsvName Policies
    }
    return $mgmntPolicies
}

Function Get-PortalConfig {
    param(
        [Parameter(Mandatory=$False)]
        [Bool]
        $Source = $False
    )
    $portalUI = Get-ObjectsFromConfig -ObjectType PortalUIConfiguration
    $navBar = Get-ObjectsFromConfig -ObjectType NavigationBarConfiguration
    $searchScope = Get-ObjectsFromConfig -ObjectType SearchScopeConfiguration
    $objVisual = Get-ObjectsFromConfig -ObjectType ObjectVisualizationConfiguration
    $homePage = Get-ObjectsFromConfig -ObjectType HomepageConfiguration

    $portalConfig = [System.Collections.ArrayList] @()
    $portalConfig.Add($portalUI)
    $portalConfig.Add($navBar)
    $portalConfig.Add($searchScope)
    $portalConfig.Add($objVisual)
    $portalConfig.Add($homePage)
    if ($Source) {
        Write-ToCsv -Objects $portalUI -CsvName PortalUI
        Write-ToCsv -Objects $navBar -CsvName NavBar 
        Write-ToCsv -Objects $searchScope -CsvName SearchScope 
        Write-ToCsv -Objects $objVisual -CsvName ObjectVisual 
        Write-ToCsv -Objects $homePage -CsvName HomePage
    } 
    return $portalConfig
}

function Get-ObjectsFromConfig {
    param(
        [Parameter(Mandatory=$True)]
        [String]
        $ObjectType
    )
    $objects = Search-Resources -XPath "/$ObjectType" -ExpectedObjectType $ObjectType
    return $objects
}

Function Write-ToCsv {
    param(
        [Parameter(Mandatory=$True)]
        [Array]
        $Objects,

        [Parameter(Mandatory=$True)]
        [String]
        $CsvName
    )
    $Objects | Export-Csv -Path "CsvConfig$CsvName.csv" -NoTypeInformation
}

Function Get-ObjectsFromCsv {
    param(
        [Parameter(Mandatory=$True)]
        [String]
        $CsvFilePath
    )
    $objs = Import-Csv -Path $CsvFilePath
    return $objs
}

Function Compare-Objects {
    param (
        [Parameter(Mandatory=$True)]
        [array]
        $ObjsSource,

        [Parameter(Mandatory=$True)]
        [array]
        $ObjsDestination
    )
    $global:Difference = [System.Collections.ArrayList]@()
    foreach ($obj in $ObjsSource) {   # source array object
            $objsDestMembers = Get-Member -InputObject $ObjsDestination # Target array objects
        if ($objsDestMembers -contains $obj) { # if object of source is in array of objects of target
            $TargetObject = $objsDestination | Where-Object $objsDestMembers -eq $obj   # target array object
            $objMembers = $obj.psobject.Members | Where-Object membertype -like 'noteproperty' # source array object members
            $TargetMembers = $TargetObject | Where-Object membertype -like 'NoteProperty' # target array object members
            foreach ($member in $objMembers) { # source array object member
                foreach ($targetMember in $TargetMembers) { # target array object member
                    if ($member.Name -eq $targetMember.Name) {
                        if ($member.Value -ne $TargetMember.Value) {
                            $global:Difference.AddRange($obj)
                            break
                        }
                    }
                }
            }
        } else {
            $global:Difference.AddRange($obj)
        }
    }
    return $Difference
}

Function Write-ToXmlFile {
    param (
        [Parameter(Mandatory=$True)]
        [Array]
        $DifferenceObjects
    )
    # Inititalization xml file
    $FileName = "configurationTemplate.xml"
    $XmlDoc = [System.Xml.XmlDocument] (Get-Content $FileName)
    $node = $XmlDoc.SelectSingleNode('//Operations')

    # Place objects in XML file
    # Iterate over the array of arrays of PsCustomObjects
    foreach ($obj in $DifferenceObjects) {
        # Operation description
        $xmlElement = $XmlDoc.CreateElement("ResourceOperation")
        $XmlOperation = $node.AppendChild($xmlElement)
        $XmlOperation.SetAttribute("operation", "Add Update")
        $XmlOperation.SetAttribute("resourceType", $Obj.ObjectType)
        # Anchor description
        $xmlElement = $XmlDoc.CreateElement("AnchorAttributes")
        $XmlAnchors = $XmlOperation.AppendChild($xmlElement)
            # Different anchors for Bindings (referentials)
        if ($obj.ObjectType -eq "BindingDescription") {
            $xmlElement1 = $XmlDoc.CreateElement("AnchorAttribute")
            $xmlElement1.Set_InnerText("BoundAttributeType")
            $xmlElement2 = $XmlDoc.CreateElement("AnchorAttribute")
            $xmlElement2.Set_InnerText("BoundObjectType")
            $XmlAnchors.AppendChild($xmlElement1)
            $XmlAnchors.AppendChild($xmlElement2)
        } else{
        $xmlElement = $XmlDoc.CreateElement("AnchorAttribute")
        $xmlElement.Set_InnerText("Name")
        $XmlAnchors.AppendChild($xmlElement)
        }
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
    $XmlDoc.Save("ConfigurationDelta.xml")
    # Confirmation
    Write-Host "Written differences in objects to a delta xml file"
    # Return the new xml 
    #[xml]$result = $XmlDoc | Select-Xml -XPath "//ResourceOperation[@resourceType='$ObjectType']"
    #[xml]$result = [System.Xml.XmlDocument] (Get-Content ".\$ObjectType.xml")
    #return $result
}

Function Import-Delta {
    <#
    .SYNOPSIS
    Import a delta or more in a MIM-setup
    
    .DESCRIPTION
    Import the differences between the source MIM setup and the target MIM setup in the target 
    MIM setup using a delta in xml
    
    .PARAMETER DeltaConfigFilePath
    The path to a delta of a configuration xml file
    
    .EXAMPLE
    Import-Delta -DeltaConfigFilePath "./ConfigurationDelta.xml"
    #>
    
    param (
        [Parameter(Mandatory=$True)]
        [string]
        $DeltaConfigFilePath
    )
        Import-RMConfig $DeltaConfigFilePath -Preview -Verbose
}