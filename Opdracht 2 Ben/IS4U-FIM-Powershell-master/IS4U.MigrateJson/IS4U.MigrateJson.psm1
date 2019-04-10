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
if(!(Get-Module -Name LithnetRMA)) {
    Import-Module LithnetRMA;
}
#Set-ResourceManagementClient -BaseAddress http://localhost:5725;
#endregion Lithnet

# Csv problem: Arrays in the PsCustomObjects do not get the required depth

Function Start-MigrationJson {
    <#
    .SYNOPSIS
    Starts the migration by either getting the source MIM setup or importing this setup in a MIM setup.
    
    .DESCRIPTION
    Call Start-MigrationJson from the IS4U.MigrateJson folder!
    If the parameter SourceOfMIMSetup is set to True, Start-MigrationJson will call the functions to
    get the resources from the configuration and converts these resources to a json format. 
    The json objects than get written to json files for each object type.
    The results in the json files are used when SourceOfMIMSetup is False.
    To import the resources, call Start-MigrationJson from this folder. It will serialize the target MIM setup resources to json and
    deserialize them so they can be compared with the resources from the source json files. 
    After that the different object(s) (new or different properties) will be written to
    a delta configuration xml file. This Lithnet format xml file then gets imported in the target MIM Setup.  
    
    .PARAMETER SourceOfMIMSetup
    If True will get the json files from the source MIM environment.
    If False will import the resources in the generated json files.

    .PARAMETER ImportSchema
    This parameter has the same concept as ImportPolicy and ImportPortal
    When True, ImportAllConfigurations will be set to false, this will cause to only import the
    imports that are set to True
    
    .EXAMPLE
    Start-MigrationJson -SourceOfMIMSetup $True
    Start-MigrationJson
    Start-MigrationJson -ImportSchema $True

    .Notes
    IMPORTANT:
    This module has been designed to only use the Start-MigrationJson function. When other function are called there is no
    guarantee the desired effect will be accomplished.
    #>
    param(
        [Parameter(Mandatory=$False)]
        [Bool]
        $ExportMIMToJson = $False,
        
        [Parameter(Mandatory=$False)]
        [Bool]
        $ImportSchema=$False,
        
        [Parameter(Mandatory=$FAlse)]
        [Bool]
        $ImportPolicy = $False,
        
        [Parameter(Mandatory=$False)]
        [Bool]
        $ImportPortal = $False
    )

    $ImportAllConfigurations = $True
    # Force the path for the ExePath to IS4U.MigrateJson
    $ExePath = $PSScriptRoot
    Set-Location $ExePath

    if ($ExportMIMToJson) {
        Write-Host "Starting export of current MIM configuration to json files. (This will overwrite existing MIM-config json files!)"
        $conf = Read-Host "Are you sure you want to proceed? [Y/N]"
        while ($conf -notmatch "[y/Y/n/N]") {
            $conf = Read-Host "Are you sure you want to proceed? [Y/N]"
        }
        if ($conf.ToLower() -eq "y"){
            Get-SchemaConfigToJson
            Get-PortalConfigToJson
            Get-PolicyConfigToJson
        } else {
            Write-Host "Export cancelled."
        }
    } else {
        # ReferentialList to store Objects and Attributes in memory for reference of bindings
        $Global:ReferentialList = @{SourceRefAttrs = [System.Collections.ArrayList]@(); DestRefAttrs = [System.Collections.ArrayList]@() 
        SourceRefObjs = [System.Collections.ArrayList]@(); DestRefObjs = [System.Collections.ArrayList]@();}
        $global:bindings = [System.Collections.ArrayList] @()
        $path = Select-FolderDialog
        if ($ImportSchema -or $ImportPolicy -or $ImportPortal) {
            $ImportAllConfigurations = $False
        }
        if ($ImportAllConfigurations) {
            Compare-SchemaJson -path $path
            Compare-PortalJson -path $path
            Compare-PolicyJson -path $path
        } else {
            if ($ImportSchema) {
                Compare-SchemaJson -path $path
            }
            if ($ImportPolicy) {
                $attrsSource = Get-ObjectsFromJson -XmlFilePath "ConfigAttributes.json"
                foreach($objt in $attrsSource) {
                    $global:ReferentialList.SourceRefAttrs.Add($objt) | Out-Null
                }
                $attrsDest = Get-ObjectsFromConfig -ObjectType AttributeTypeDescription
                foreach($objt in $attrsDest) {
                    $global:ReferentialList.DestRefAttrs.Add($objt) | Out-Null
                }
                Compare-PolicyJson -path $path
            }
            if ($ImportPortal) {
                Compare-PortalJson -path $path
            }
        }
        if ($bindings) {
            Write-ToXmlFile -DifferenceObjects $bindings -path $path -Anchor @("Name")
        }
        Remove-Variable ReferentialList -Scope Global
        Remove-Variable bindings -Scope Global

        if (Test-Path -Path "$Path\ConfigurationDelta.xml") {
            Write-Host "Select objects to be imported." -ForegroundColor "Green"
            $exeFile = "$ExePath\FimDelta.exe"
            Start-Process $exeFile "$Path\ConfigurationDelta.xml" -Wait
            if (Test-Path -Path "$Path\ConfigurationDelta2.xml") {
                Import-Delta -DeltaConfigFilePath "$path\ConfigurationDelta2.xml"
            } else {
                Import-Delta -DeltaConfigFilePath "$path\ConfigurationDelta.xml"
            }
        } else {
            Write-Host "No configurationDelta file found: Not created or no differences."
        }
    }
}

Function Get-SchemaConfigToJson {
    param(
        [Parameter(Mandatory=$False)]
        [Bool]
        $Source = $False
    )

    $attrs = Get-ObjectsFromConfig -ObjectType AttributeTypeDescription
    $objs = Get-ObjectsFromConfig -ObjectType ObjectTypeDescription
    $binds = Get-ObjectsFromConfig -ObjectType BindingDescription
    $constSpec = Get-ObjectsFromConfig -ObjectType ConstantSpecifier

    Convert-ToJson -Objects $attrs -JsonName Attributes
    Convert-ToJson -Objects $objs -JsonName objectTypes
    Convert-ToJson -Objects $binds -JsonName Bindings
    Convert-ToJson -Objects $constSpec -JsonName ConstantSpecifiers
}

Function Compare-SchemaJson {
    param(
        [Parameter(Mandatory=$True)]
        [String]
        $path
    )
    Write-Host "Starting compare of Schema configuration..."
    # Source of objects to be imported
    $attrsSource = Get-ObjectsFromJson -JsonFilePath "ConfigAttributes.json"
    foreach($obj in $attrsSource) {
        $Global:ReferentialList.SourceRefAttrs.Add($obj) | Out-Null
    }
    $objsSource = Get-ObjectsFromJson -JsonFilePath "ConfigObjectTypes.json"
    foreach($obj in $objsSource) {
        $Global:ReferentialList.SourceRefObjs.Add($obj) | Out-Null
    }
    $bindingsSource = Get-ObjectsFromJson -JsonFilePath "ConfigBindings.json"
    $constSpecsSource = Get-ObjectsFromJson -JsonFilePath "ConfigConstantSpecifiers.json"
    
    # Target Setup objects, comparing purposes
    # Makes target a json and then converts it to an object
    $attrsDest = Get-ObjectsFromConfig -ObjectType AttributeTypeDescription
    foreach($obj in $attrsDest) {
        $Global:ReferentialList.DestRefAttrs.Add($obj) | Out-Null
    }
    $objsDest = Get-ObjectsFromConfig -ObjectType ObjectTypeDescription
    foreach($obj in $objsDest) {
        $Global:ReferentialList.DestRefObjs.Add($obj) | Out-Null
    }
    $bindingsDest = Get-ObjectsFromConfig -ObjectType BindingDescription
    $constSpecsDest = Get-ObjectsFromConfig -ObjectType ConstantSpecifier

    # Comparing of the Source and Target Setup to create delta xml file
    Compare-Objects -ObjsSource $attrsSource -ObjsDestination $attrsDest -path $path
    Compare-Objects -ObjsSource $objsSource -ObjsDestination $objsDest -path $path
    Compare-Objects -ObjsSource $bindingsSource -ObjsDestination $bindingsDest -Anchor @("BoundAttributeType", "BoundObjectType") -path $path
    Compare-Objects -ObjsSource $constSpecsSource -ObjsDestination $constSpecsDest -Anchor @("BoundAttributeType", "BoundObjectType", "ConstantValueKey") -path $path
    Write-Host "Compare of Schema configuration completed."
}

Function Get-PolicyConfigToJson {
    param(
        [Parameter(Mandatory=$False)]
        [Bool]
        $Source = $False
    )

    $manPol = Get-ObjectsFromConfig -ObjectType ManagementPolicyRule
    $sets = Get-ObjectsFromConfig -ObjectType Set
    $workFlowDef = Get-ObjectsFromConfig -ObjectType WorkflowDefinition
    $emailTem = Get-ObjectsFromConfig -ObjectType EmailTemplate
    $filterScope = Get-ObjectsFromConfig -ObjectType FilterScope
    $actInfConf = Get-ObjectsFromConfig -ObjectType ActivityInformationConfiguration
    $function = Get-ObjectsFromConfig -ObjectType Function
    $syncRule = Get-ObjectsFromConfig -ObjectType SynchronizationRule
    $syncFilter = Get-ObjectsFromConfig -ObjectType SynchronizationFilter

    Convert-ToJson -Objects $manPol -JsonName ManagementPolicyRules
    Convert-ToJson -Objects $sets -JsonName Sets
    Convert-ToJson -Objects $workFlowDef -JsonName WorkflowDefinitions
    Convert-ToJson -Objects $emailTem -JsonName EmailTemplates
    Convert-ToJson -Objects $filterScope -JsonName FilterScopes
    Convert-ToJson -Objects $actInfConf -JsonName ActivityInformationConfigurations
    Convert-ToJson -Objects $function -JsonName Functions
    if($syncRule){
        Convert-ToJson -Objects $syncRule -JsonName SynchronizationRules
    }
    Convert-ToJson -Objects $syncFilter -JsonName SynchronizationFilters
}

Function Compare-PolicyJson {
    param(
        [Parameter(Mandatory=$True)]
        [String]
        $path
    )
    Write-Host "Starting compare of Policy configuration..."
    # Source of objects to be imported
    $mgmntPlciesSrc = Get-ObjectsFromJson -JsonFilePath "ConfigManagementPolicyRules.json"
    $setsSrc = Get-ObjectsFromJson -JsonFilePath "ConfigSets.json"
    $workflowSrc = Get-ObjectsFromJson -JsonFilePath "ConfigWorkflowDefinitions.json"
    $emailSrc = Get-ObjectsFromJson -JsonFilePath "ConfigEmailTemplates.json"
    $filtersSrc = Get-ObjectsFromJson -JsonFilePath "ConfigFilterScopes.json"
    $activitySrc = Get-ObjectsFromJson -JsonFilePath "ConfigActivityInformationConfigurations.json"
    $funcSrc = Get-ObjectsFromJson -JsonFilePath "ConfigFunctions.json"
    $syncRSrc = Get-ObjectsFromJson -JsonFilePath "ConfigSynchronizationRules.json"
    $syncFSrc = Get-ObjectsFromJson -JsonFilePath "ConfigSynchronizationFilters.json"

    # Target Setup objects, comparing purposes
    $mgmntPlciesDest = Get-ObjectsFromConfig -ObjectType ManagementPolicyRule
    $setsDest = Get-ObjectsFromConfig -ObjectType Set
    $workflowDest = Get-ObjectsFromConfig -ObjectType WorkflowDefinition
    $emailDest = Get-ObjectsFromConfig -ObjectType EmailTemplate
    $filtersDest = Get-ObjectsFromConfig -ObjectType FilterScope
    $activityDest = Get-ObjectsFromConfig -ObjectType ActivityInformationConfiguration
    $funcDest = Get-ObjectsFromConfig -ObjectType Function 
    $syncRDest = Get-ObjectsFromConfig -ObjectType SynchronizationRule
    $syncFDest = Get-ObjectsFromConfig -ObjectType SynchronizationFilter

    # Comparing of the Source and Target Setup to create delta xml file
    Compare-Objects -ObjsSource $mgmntPlciesSrc -ObjsDestination $mgmntPlciesDest -Anchor @("DisplayName") -path $path
    # Only import sets if policy exists for permission
    #Compare-Objects -ObjsSource $setsSrc -ObjsDestination $setsDest -Anchor @("DisplayName") -path $path
    Compare-Objects -ObjsSource $workflowSrc -ObjsDestination $workflowDest -Anchor @("DisplayName") -path $path
    Compare-Objects -ObjsSource $emailSrc -ObjsDestination $emailDest -Anchor @("DisplayName") -path $path
    Compare-Objects -ObjsSource $filtersSrc -ObjsDestination $filtersDest -Anchor @("DisplayName") -path $path
    Compare-Objects -ObjsSource $activitySrc -ObjsDestination $activityDest -Anchor @("DisplayName") -path $path
    Compare-Objects -ObjsSource $funcSrc -ObjsDestination $funcDest -Anchor @("DisplayName") -path $path
    if ($syncRSrc) {
        Compare-Objects -ObjsSource $syncRSrc -ObjsDestination $syncRDest -Anchor @("DisplayName") -path $path
    }
    Compare-Objects -ObjsSource $syncFSrc -ObjsDestination $syncFDest -Anchor @("DisplayName") -path $path
    Write-Host "Compare of Policy configuration completed."
}

Function Get-PortalConfigToJson {
    param(
        [Parameter(Mandatory=$False)]
        [Bool]
        $Source = $False
    )

    $homeConf = Get-ObjectsFromConfig -ObjectType HomepageConfiguration
    $portalUIConf = Get-ObjectsFromConfig -ObjectType PortalUIConfiguration
    $conf = Get-ObjectsFromConfig -ObjectType Configuration
    $naviBarConf = Get-ObjectsFromConfig -ObjectType NavigationBarConfiguration
    $searchScopeConf = Get-ObjectsFromConfig -ObjectType SearchScopeConfiguration
    $objectVisualConf = Get-ObjectsFromConfig -ObjectType ObjectVisualizationConfiguration

    Convert-ToJson -Objects $homeConf -JsonName HomepageConfigurations
    Convert-ToJson -Objects $portalUIConf -JsonName PortalUIConfigurations
    if($conf){
        Convert-ToJson -Objects $conf -JsonName Configurations
    }
    Convert-ToJson -Objects $naviBarConf -JsonName NavigationBarConfigurations
    Convert-ToJson -Objects $searchScopeConf -JsonName SearchScopeConfigurations
    Convert-ToJson -Objects $objectVisualConf -JsonName ObjectVisualizationConfigurations
}

Function Compare-PortalJson {
    param(
        [Parameter(Mandatory=$True)]
        [String]
        $path
    )
    Write-Host "Starting compare of Portal configuration..."
    # Source of objects to be imported
    $UISrc = Get-ObjectsFromJson -JsonFilePath "ConfigPortalUIConfigurations.json"
    $navSrc = Get-ObjectsFromJson -JsonFilePath "ConfigNavigationBarConfigurations.json"
    $srchScopeSrc = Get-ObjectsFromJson -JsonFilePath "ConfigSearchScopeConfigurations.json"
    $objVisSrc = Get-ObjectsFromJson -JsonFilePath "ConfigObjectVisualizationConfigurations.json"
    $homePSrc = Get-ObjectsFromJson -JsonFilePath "ConfigHomepageConfigurations.json"
    $confSrc = Get-ObjectsFromJson -JsonFilePath "ConfigConfigurations.json"

    # Target Setup objects, comparing purposes
    $UIDest = Get-ObjectsFromConfig -ObjectType PortalUIConfiguration
    $navDest = Get-ObjectsFromConfig -ObjectType NavigationBarConfiguration
    $srchScopeDest = Get-ObjectsFromConfig -ObjectType SearchScopeConfiguration
    $objVisDest = Get-ObjectsFromConfig -ObjectType ObjectVisualizationConfiguration
    $homePDest = Get-ObjectsFromConfig -ObjectType HomepageConfiguration
    $confDest = Get-ObjectsFromConfig -ObjectType Configuration

    # Comparing of the Source and Target Setup to create delta xml file
    Compare-Objects -ObjsSource $UISrc -ObjsDestination $UIDest -Anchor @("DisplayName") -path $path
    Compare-Objects -ObjsSource $navSrc -ObjsDestination $navDest -Anchor @("DisplayName") -path $path
    Compare-Objects -ObjsSource $srchScopeSrc -ObjsDestination $srchScopeDest -Anchor @("DisplayName", "Order") -path $path
    Compare-Objects -ObjsSource $objVisSrc -ObjsDestination $objVisDest -Anchor @("DisplayName") -path $path
    Compare-Objects -ObjsSource $homePSrc -ObjsDestination $homePDest -Anchor @("DisplayName") -path $path
    # Could be empty
    if ($confSrc -and $confDest) {
        Compare-MimObjects -ObjsSource $confSrc -ObjsDestination $confDest -Anchor @("DisplayName") -path $path 
    }
    Write-Host "Compare of Portal configuration completed."
}

Function Get-ObjectsFromConfig {
    param(
        [Parameter(Mandatory=$True)]
        [String]
        $ObjectType
    )
    # This looks for objectTypes and expects objects with the type ObjectType
    $objects = Search-Resources -Xpath "/$ObjectType" -ExpectedObjectType $ObjectType
    # Read only members, not needed for import (are generated in the MIM-Setup)
    $illegalMembers = @("CreatedTime", "Creator", "DeletedTime", "DetectedRulesList",
    "ExpectedRulesList", "ResourceTime", "ComputedMember")
    # Makes target a json and then converts it to an object
    if ($objects) {
        foreach($obj in $objects){
            foreach($illMem in $illegalMembers){
                $obj.psobject.properties.Remove("$illMem")
            }
        }
        $updatedObjs = ConvertTo-Json -InputObject $objects -Depth 4
        $objects = ConvertFrom-Json -InputObject $updatedObjs
    } else {
        Write-Host "No objects found to write to json"
    }
    return $objects
}

Function Convert-ToJson {
    param(
        [Parameter(Mandatory=$True)]
        [Array]
        $Objects,

        [Parameter(Mandatory=$True)]
        [String]
        $JsonName
    )

    foreach ($obj in $objects) {
        $objMembers = $obj.psobject.members | Where-Object membertype -Like 'noteproperty'
        $obj = $objMembers
    }
    ConvertTo-Json -InputObject $Objects -Depth 4 -Compress | Out-File "./Config$JsonName.json"
}

Function Get-ObjectsFromJson {
    param(
        [Parameter(Mandatory=$True)]
        [String]
        $JsonFilePath
    )

    try {
        $objs = Get-Content $JsonFilePath | ConvertFrom-Json
        return $objs
    } catch [System.Management.Automation.ItemNotFoundException] {
        Write-Host "File not found $JsonFilePath" -ForegroundColor Red
    }
}

Function Compare-Objects {
    param (
        [Parameter(Mandatory=$True)]
        [array]
        $ObjsSource,

        [Parameter(Mandatory=$True)]
        [array]
        $ObjsDestination,

        [Parameter(Mandatory=$False)]
        [Array]
        $Anchor = @("Name"),
        
        [Parameter(Mandatory=$true)]
        [String]
        $path
    )
    $i = 1
    $total = $ObjsSource.Count
    $difference = [System.Collections.ArrayList] @()
    foreach ($obj in $ObjsSource){
        $type = $obj.ObjectType
        #Write-Progress -Activity "Comparing objects" -Status "Completed compares out of $total" -PercentComplete ($i/$total*100)
        Write-Host "`rComparing $type objects: $i/$total... `t" -NoNewline
        $i++
        if ($Anchor.Count -eq 1) {
            $obj2 = $ObjsDestination | Where-Object{$_.($Anchor[0]) -eq $obj.($Anchor[0])}
        } elseif ($Anchor.Count -eq 2) { 
            # When ObjectType is BindingDescription or needs two anchors to find one object
            if ($Anchor -contains "BoundAttributeType" -and $Anchor -contains "BoundObjectType") { 
                # Find the corresponding object that matches the BoundAttributeType ID
                $RefToAttrSrc = $Global:ReferentialList.SourceRefAttrs | Where-Object{$_.ObjectID.Value -eq $obj.BoundAttributeType.Value}
                # Find the corresponding object that matches the source binded attribute with the destination attibute by Name
                $RefToAttrDest = $Global:ReferentialList.DestRefAttrs | Where-Object{$_.Name -eq $RefToAttrSrc.Name}

                $RefToObjSrc = $Global:ReferentialList.SourceRefObjs | Where-Object{$_.ObjectID.Value -eq $obj.BoundObjectType.Value}
                $RefToObjDest = $Global:ReferentialList.DestRefObjs | Where-Object{$_.Name -eq $RefToObjSrc.Name}

                if ($RefToAttrDest -and $RefToObjDest) {
                    #obj2 gets the correct object that corresponds to the source object
                    $obj2 = $ObjsDestination | Where-Object {$_.BoundAttributeType -like $RefToAttrDest.ObjectID -and 
                    $_.BoundObjectType -like $RefToObjDest.ObjectID}
                } else {
                    $obj2 = ""
                }

            } else {
                $obj2 = $ObjsDestination | Where-Object {$_.($Anchor[0]) -like $obj.($Anchor[0]) -and `
                $_.($Anchor[1]) -like $obj.($Anchor[1])}
            }
        } else { 
            # When ObjectType needs multiple anchors to find unique object
            if ($Anchor -contains "BoundAttributeType" -and $Anchor -contains "BoundObjectType") {
                $RefToAttrSrc = $Global:ReferentialList.SourceRefAttrs | Where-Object{$_.ObjectID.Value -eq $obj.BoundAttributeType.Value}
                $RefToAttrDest = $Global:ReferentialList.DestRefAttrs | Where-Object{$_.Name -eq $RefToAttrSrc.Name}

                $RefToObjSrc = $Global:ReferentialList.SourceRefObjs | Where-Object{$_.ObjectID.Value -eq $obj.BoundObjectType.Value}
                $RefToObjDest = $Global:ReferentialList.DestRefObjs | Where-Object{$_.Name -eq $RefToObjSrc.Name}

                if ($RefToAttrDest -and $RefToObjDest) {
                    #obj2 gets the correct object that corresponds to the source object
                    $obj2 = $ObjsDestination | Where-Object {$_.BoundAttributeType -like $RefToAttrDest.ObjectID -and 
                    $_.BoundObjectType -like $RefToObjDest.ObjectID}
                } else {
                    $obj2 = ""
                }

            } else {
                $obj2 = $ObjsDestination | Where-Object {$_.($Anchor[0]) -like $obj.($Anchor[0]) -and `
                $_.($Anchor[1]) -like $obj.($Anchor[1]) -and $_.($Anchor[2]) -eq $obj.($Anchor[2])}
            }
        }   
        # If there is no match between the objects from different sources, the not found object will be added for import
        if (!$obj2) {
            Write-Host "New object found:"
            Write-Host $obj -ForegroundColor yellow
            if ($Anchor -contains "BoundAttributeType" -and $Anchor -contains "BoundObjectType") {
                if ($bindings -notcontains $RefToAttrSrc) {
                    $global:bindings.Add($RefToAttrSrc) | Out-Null
                }
                if ($bindings -notcontains $RefToObjSrc) {
                    $global:bindings.Add($RefToObjSrc) | Out-Null   
                }
            }
            $difference.Add($obj)
        } else {
            # Give the object the ObjectID from the target object => comparing reasons
            $obj.ObjectID = $obj2.ObjectID
            if ($Anchor -contains "BoundAttributeType" -and $Anchor -contains "BoundObjectType") {
                $obj.BoundAttributeType = $obj2.BoundAttributeType
                $obj.BoundObjectType = $obj2.BoundObjectType
            }
            
            $compResult = Compare-Object -ReferenceObject $obj.psobject.members -DifferenceObject $obj2.psobject.members -PassThru
            # If difference found
            if ($compResult) {
                # To visually compare the differences yourself
                #Write-Host $obj -BackgroundColor Green -ForegroundColor Black
                #Write-Host $obj2 -BackgroundColor White -ForegroundColor Black
                $compObj = $compResult | Where-Object {$_.SideIndicator -eq '<='} # Difference in original!
                $resultComp = $compObj | Where-Object membertype -Like 'noteproperty'
                $newObj = [PSCustomObject]@{}
                foreach ($mem in $resultComp) {
                    $newObj | Add-Member -NotePropertyName $mem.Name -NotePropertyValue $mem.Value
                }
                Write-host "Different object properties found:"
                Write-host $newObj -ForegroundColor Yellow -BackgroundColor Black
                $difference.Add($newObj)
                if ($newObj.psobject.Properties.Name -contains "BoundAttributeType" -and 
                $newObj.psobject.properties.Name -contains "BoundObjectType") {
                    if ($bindings -notcontains $RefToAttrSrc) {
                        $global:bindings.Add($RefToAttrSrc) | Out-Null
                    }
                    if ($bindings -notcontains $RefToObjSrc) {
                        $global:bindings.Add($RefToObjSrc) | Out-Null   
                    }
                }
            }
        }
    }
    if ($difference) {
        Write-ToXmlFile -DifferenceObjects $difference -path $path -Anchor $Anchor
    } else {
        Write-Host "No differences found!" -ForegroundColor Green
    }
}

Function Write-ToXmlFile {
    param (
        [Parameter(Mandatory=$True)]
        [System.Collections.ArrayList]
        $DifferenceObjects,

        [Parameter(Mandatory = $True)]
        [String]
        $path,

        [Parameter(Mandatory=$True)]
        [Array]
        $Anchor
    )
    # Inititalization xml file
    $FileName = "$path/configurationDelta.xml"
    # Create empty starting lithnet configuration xml file
    if (!(Test-Path -Path $FileName)) {
        [xml]$Doc = New-Object System.Xml.XmlDocument
        $initalElement = $Doc.CreateElement("Lithnet.ResourceManagement.ConfigSync")
        $operationsElement = $Doc.CreateElement("Operations")
        $declaration = $Doc.CreateXmlDeclaration("1.0","UTF-8",$null)
        $Doc.AppendChild($declaration) | Out-Null
        $startNode = $Doc.AppendChild($initalElement)
        $startNode.AppendChild($operationsElement) | Out-Null
        $Doc.Save($FileName)
    }
    if (!(Test-Path -Path $FileName)) {
        Write-Host "File not found"
        break
    }
    $XmlDoc = [System.Xml.XmlDocument] (Get-Content $FileName)
    $node = $XmlDoc.SelectSingleNode('//Operations')

    # Place objects in XML file
    # Iterate over the array of PsCustomObjects
    foreach ($obj in $DifferenceObjects) {
        # Operation description
        $xmlElement = $XmlDoc.CreateElement("ResourceOperation")
        $XmlOperation = $node.AppendChild($xmlElement)
        $XmlOperation.SetAttribute("operation", "Add Update")
        $XmlOperation.SetAttribute("resourceType", $Obj.ObjectType)
        # Anchor description
        $xmlElement = $XmlDoc.CreateElement("AnchorAttributes")
        $XmlAnchors = $XmlOperation.AppendChild($xmlElement)
        # Different anchors for Bindings (or referentials)
        foreach($anch in $Anchor){
            $xmlElement = $XmlDoc.CreateElement("AnchorAttribute")
            $xmlElement.Set_InnerText($anch)
            $XmlAnchors.AppendChild($xmlElement)
        }
        # Attributes of the object
        $xmlEle = $XmlDoc.CreateElement("AttributeOperations")
        $XmlAttributes = $XmlOperation.AppendChild($xmlEle)
        # Get the PsCustomObject members from the MIM service without the hidden/extra members
        $objMembers = $obj.psobject.Members | Where-Object membertype -like 'noteproperty'
        # iterate over the PsCustomObject members and append them to the AttributeOperations element
        foreach ($member in $objMembers) {
            # Skip ObjectType (already used in ResourceOperation)
            if ($member.Name -eq "ObjectType") { continue }
            # insert ArrayList values into the configuration
            if($member.Value){
                if ($member.Value.GetType().Name -eq "ArrayList") { 
                    if($member.Name -eq "ExplicitMember") {
                        continue
                    }
                    foreach ($m in $member.Value) {
                        $xmlVarElement = $XmlDoc.CreateElement("AttributeOperation")
                        if ($member.Name -eq "AllowedAttributes"){
                            $RefToAttrSrc = $Global:ReferentialList.SourceRefAttrs | Where-Object {
                                $_.ObjectID.Value -eq $m.Value
                            }
                            $xmlVarElement.Set_InnerText($RefToAttrSrc.ObjectID.Value)
                            $xmlVariable = $XmlAttributes.AppendChild($xmlVarElement)
                            $xmlVariable.SetAttribute("type", "xmlref")
                            if($bindings -notcontains $RefToAttrSrc) {
                                $Global:bindings.Add($RefToAttrSrc) | Out-Null
                            }
                        } else {
                            $xmlVarElement.Set_InnerText($m)
                            $xmlVariable = $XmlAttributes.AppendChild($xmlVarElement)
                        }
                        
                        $xmlVariable.SetAttribute("operation", "add")
                        $xmlVariable.SetAttribute("name", $member.Name)
                    }
                    continue
                }
            }
            # referencing purposes, no need in the attributes itself (Lithnet does this)
            if ($member.Name -eq "ObjectID") {
                # set the objectID of the object as the id of the xml node
                $XmlOperation.SetAttribute("id", $member.Value.Value)
                continue # Import-RmConfig creates an objectID in the new setup
            }
            $xmlVarElement = $XmlDoc.CreateElement("AttributeOperation")
            if ($member.Name -eq "BoundAttributeType" -or $member.Name -eq "BoundObjectType") {
                $xmlVarElement.Set_InnerText($member.Value.Value)
                $xmlVariable = $XmlAttributes.AppendChild($xmlVarElement)
                $xmlVariable.SetAttribute("operation", "replace")
                $xmlVariable.SetAttribute("name", $member.Name)
                $xmlVariable.SetAttribute("type", "xmlref")
                continue
            }
            $xmlVarElement.Set_InnerText($member.Value)
            $xmlVariable = $XmlAttributes.AppendChild($xmlVarElement)
            $xmlVariable.SetAttribute("operation", "replace")
            $xmlVariable.SetAttribute("name", $member.Name)
        }
    }
    # Save the xml 
    $XmlDoc.Save($FileName)
    # Confirmation
    Write-Host "Written differences in objects to the delta xml file (ConfigurationDelta.xml)"
}

Function Select-FolderDialog{
    <#
    .SYNOPSIS
    Prompts the user for a folder browser.
    
    .DESCRIPTION
    This function makes the user choose a destination folder to save the xml configuration delta.
    If The user aborts this, the script will stop executing.
    
    .LINK
    https://stackoverflow.com/questions/11412617/get-a-folder-path-from-the-explorer-menu-to-a-powershell-variable
    #>
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null     

    $objForm = New-Object System.Windows.Forms.FolderBrowserDialog
    $objForm.Rootfolder = "Desktop"
    $objForm.Description = "Select folder to save the ConfigurationDelta.xml"
    $Show = $objForm.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true }))
    If ($Show -eq "OK") {
        Return $objForm.SelectedPath
    } Else {
        Write-Error "Operation cancelled by user." -ErrorAction Stop
    }
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