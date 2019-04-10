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
    <#
    .SYNOPSIS
    Starts the migration by either getting the source MIM setup or importing this setup in a different target MIM setup.
    
    .DESCRIPTION
    Call Start-Migration from the IS4U.Migrate folder!
    If the parameter ExportMIMToXml is set to True, Start-Migration will call the functions to
    get the resources from the configuration and converts these resources to a CliXml format. 
    The CliXml objects then get written to xml files for each object type.
    The results in xml files are used when ExportMIMToXml is False.
    To import the resources, call Start-Migration from this folder. It will serialize the target MIM setup resources to clixml and
    deserialize them so they can be compared with the resources from the source xml files. 
    Finally the different object(s) (new or different properties) will be written to
    a delta configuration xml file. This (Lithnet format) xml file then gets imported in the target MIM Setup.  
    
    .PARAMETER ExportMIMToXml
    If True will get the xml files from the source MIM environment.
    If False will import the resources in the generated xml files.

    .PARAMETER ImportSchema
    This parameter is the same concept as ImportPolicy and ImportPortal:
    When True, ImportAllConfigurations will be set to false, this will cause to only import the
    configurations where the parameters are set to True, in this case the Schema configuration.
    
    .EXAMPLE
    Start-Migration -ExportMIMToXml $True
    Start-Migration
    Start-Migration -ImportPolicy $True

    .Notes
    IMPORTANT:
    This module has been designed to only use the Start-Migration function. When other function are called there is no
    guarantee the desired effect will be accomplished.
    #>
    param(
        [Parameter(Mandatory=$False)]
        [Bool]
        $ExportMIMToXml = $False,
        
        [Parameter(Mandatory=$False)]
        [Bool]
        $ImportSchema=$False,
        
        [Parameter(Mandatory=$False)]
        [Bool]
        $ImportPolicy = $False,
        
        [Parameter(Mandatory=$False)]
        [Bool]
        $ImportPortal = $False
    )
    $ImportAllConfigurations = $True
    # Force directory to .\IS4U.Migrate
    $ExePath = $PSScriptRoot
    #Set-Location $ExePath

    if ($ExportMIMToXml) {
        Write-Host "Starting export of current MIM configuration to xml files. (This will overwrite existing MIM-config xml files!)"
        $conf = Read-Host "Are you sure you want to proceed? [Y/N]"
        while ($conf -notmatch "[y/Y/n/N]") {
            $conf = Read-Host "Are you sure you want to proceed? [Y/N]"
        }
        if ($conf.ToLower() -eq "y"){
            Get-SchemaConfigToXml
            Get-PortalConfigToXml
            Get-PolicyConfigToXml
        } else {
            Write-Host "Export cancelled."
        }
        
    } else {
        # ReferentialList to store Objects and Attributes in memory for reference of bindings
        $global:ReferentialList = @{SourceRefObjs = [System.Collections.ArrayList]@(); DestRefObjs = [System.Collections.ArrayList] @();
        SourceRefAttrs = [System.Collections.ArrayList]@(); DestRefAttrs = [System.Collections.ArrayList]@()}
        $global:bindings = [System.Collections.ArrayList] @()
        $path = Select-FolderDialog
        if ($ImportSchema -or $ImportPolicy -or $ImportPortal) {
            $ImportAllConfigurations = $False
        }
        if ($ImportAllConfigurations) {
            Compare-Schema -path $path
            Compare-Portal -path $path
            Compare-Policy -path $path
        } else {
            if ($ImportSchema) {
                Compare-Schema -path $path
            }
            if ($ImportPolicy) {
                $attrsSource = Get-ObjectsFromXml -XmlFilePath "ConfigAttributes.xml"
                foreach($objt in $attrsSource) {
                    $global:ReferentialList.SourceRefAttrs.Add($objt) | Out-Null
                }
                $attrsDest = Get-ObjectsFromConfig -ObjectType AttributeTypeDescription
                foreach($objt in $attrsDest) {
                    $global:ReferentialList.DestRefAttrs.Add($objt) | Out-Null
                }
                Compare-Policy -path $path
            }
            if ($ImportPortal) {
                Compare-Portal -path $path
            }
        }
        if ($bindings) {
            Write-ToXmlFile -DifferenceObjects $Global:bindings -path $path -Anchor @("Name")
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

Function Compare-Schema {
    param(
        [Parameter(Mandatory=$True)]
        [String]
        $Path
    )
    # Source of objects to be imported
    $attrsSource = Get-ObjectsFromXml -XmlFilePath "ConfigAttributes.xml"
    foreach($objt in $attrsSource) {
        $global:ReferentialList.SourceRefAttrs.Add($objt) | Out-Null
    }
    $objsSource = Get-ObjectsFromXml -XmlFilePath "ConfigObjectTypes.xml"
    foreach($objt in $objsSource) {
        $global:ReferentialList.SourceRefObjs.Add($objt) | Out-Null
    }
    $bindingsSource = Get-ObjectsFromXml -XmlFilePath "ConfigBindings.xml"
    $cstspecifiersSource = Get-ObjectsFromXml -XmlFilePath "ConfigConstSpecifiers.xml"
    
    # Target Setup objects
    $attrsDest = Get-ObjectsFromConfig -ObjectType AttributeTypeDescription
    foreach($objt in $attrsDest) {
        $global:ReferentialList.DestRefAttrs.Add($objt) | Out-Null
    }
    $objsDest = Get-ObjectsFromConfig -ObjectType ObjectTypeDescription
    foreach($objt in $objsDest) {
        $global:ReferentialList.DestRefObjs.Add($objt) | Out-Null
    }
    $bindingsDest = Get-ObjectsFromConfig -ObjectType BindingDescription
    $cstspecifiersDest = Get-ObjectsFromConfig -ObjectType ConstantSpecifier

    # Comparing of the Source and Target Setup to create delta xml file
    Write-Host "Starting compare of Schema configuration..."
    Compare-MimObjects -ObjsSource $attrsSource -ObjsDestination $attrsDest -path $path
    Compare-MimObjects -ObjsSource $objsSource -ObjsDestination $objsDest -path $path
    Compare-MimObjects -ObjsSource $bindingsSource -ObjsDestination $bindingsDest `
    -Anchor @("BoundAttributeType", "BoundObjectType") -path $path
    Compare-MimObjects -ObjsSource $cstspecifiersSource -ObjsDestination $cstspecifiersDest `
    -Anchor @("BoundAttributeType", "BoundObjectType", "ConstantValueKey") -path $path
    Write-Host "Compare of Schema configuration completed."
}

Function Compare-Policy {
    param(
        [Parameter(Mandatory=$true)]
        [String]
        $path
    )
    # Source of objects to be imported
    $mgmntPlciesSrc = Get-ObjectsFromXml -xmlFilePath "ConfigPolicies.xml"
    $setsSrc = Get-ObjectsFromXml -xmlFilePath "ConfigSets.xml"
    $workflowSrc = Get-ObjectsFromXml -xmlFilePath "ConfigWorkflows.xml"
    $emailSrc = Get-ObjectsFromXml -xmlFilePath "ConfigEmailTemplates.xml"
    $filtersSrc = Get-ObjectsFromXml -xmlFilePath "ConfigFilterScopes.xml"
    $activitySrc = Get-ObjectsFromXml -xmlFilePath "ConfigActivityInfo.xml"
    $funcSrc = Get-ObjectsFromXml -xmlFilePath "ConfigPolicyFunctions.xml"
    $syncRSrc = Get-ObjectsFromXml -xmlFilePath "ConfigSyncRules.xml"
    $syncFSrc = Get-ObjectsFromXml -xmlFilePath "ConfigSyncFilters.xml"

    # Target Setup objects
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
    Write-Host "Starting compare of Policy configuration..."
    Compare-MimObjects -ObjsSource $mgmntPlciesSrc -ObjsDestination $mgmntPlciesDest -Anchor @("DisplayName") -path $path
    # Only import sets if policy exists for permission
    #Compare-MimObjects -ObjsSource $setsSrc -ObjsDestination $setsDest -Anchor @("DisplayName") -path $path
    Compare-MimObjects -ObjsSource $workflowSrc -ObjsDestination $workflowDest -Anchor @("DisplayName") -path $path
    Compare-MimObjects -ObjsSource $emailSrc -ObjsDestination $emailDest -Anchor @("DisplayName") -path $path
    Compare-MimObjects -ObjsSource $filtersSrc -ObjsDestination $filtersDest -Anchor @("DisplayName") -path $path
    Compare-MimObjects -ObjsSource $activitySrc -ObjsDestination $activityDest -Anchor @("DisplayName") -path $path
    Compare-MimObjects -ObjsSource $funcSrc -ObjsDestination $funcDest -Anchor @("DisplayName") -path $path
    if ($syncRSrc) {
    Compare-MimObjects -ObjsSource $syncRSrc -ObjsDestination $syncRDest -Anchor @("DisplayName") -path $path
    }
    Compare-MimObjects -ObjsSource $syncFSrc -ObjsDestination $syncFDest -Anchor @("DisplayName") -path $path
    Write-Host "Compare of Policy configuration completed."
}

Function Compare-Portal {
    param(
        [Parameter(Mandatory=$True)]
        [String]
        $path
    )
    # Source of objects to be imported
    $UISrc = Get-ObjectsFromXml -xmlFilePath "ConfigPortalUI.xml"
    $navSrc = Get-ObjectsFromXml -xmlFilePath "ConfigNavBar.xml"
    $srchScopeSrc = Get-ObjectsFromXml -xmlFilePath "ConfigSearchScope.xml"
    $objVisSrc = Get-ObjectsFromXml -xmlFilePath "ConfigObjectVisual.xml"
    $homePSrc = Get-ObjectsFromXml -xmlFilePath "ConfigHomePage.xml"
    $configSrc = Get-ObjectsFromXml -xmlFilePath "ConfigConfigur.xml"

    # Target Setup objects
    $UIDest = Get-ObjectsFromConfig -ObjectType PortalUIConfiguration
    $navDest = Get-ObjectsFromConfig -ObjectType NavigationBarConfiguration
    $srchScopeDest = Get-ObjectsFromConfig -ObjectType SearchScopeConfiguration
    $objVisDest = Get-ObjectsFromConfig -ObjectType ObjectVisualizationConfiguration
    $homePDest = Get-ObjectsFromConfig -ObjectType HomepageConfiguration
    $configDest = Get-ObjectsFromConfig -ObjectType Configuration

    # Comparing of the Source and Target Setup to create delta xml file
    Write-Host "Starting compare of Portal configuration..."
    Compare-MimObjects -ObjsSource $UISrc -ObjsDestination $UIDest -Anchor @("DisplayName") -path $path
    Compare-MimObjects -ObjsSource $navSrc -ObjsDestination $navDest -Anchor @("DisplayName") -path $path
    Compare-MimObjects -ObjsSource $srchScopeSrc -ObjsDestination $srchScopeDest -Anchor @("DisplayName", "Order") -path $path
    Compare-MimObjects -ObjsSource $objVisSrc -ObjsDestination $objVisDest -Anchor @("DisplayName") -path $path
    Compare-MimObjects -ObjsSource $homePSrc -ObjsDestination $homePDest -Anchor @("DisplayName") -path $path
    # Could be empty
    if ($configSrc -and $configDest) {
        Compare-MimObjects -ObjsSource $configSrc -ObjsDestination $configDest -Anchor @("DisplayName") -path $path
    }
    Write-Host "Compare of Portal configuration completed."
}

Function Get-SchemaConfigToXml {
    $attrs = Get-ObjectsFromConfig -ObjectType AttributeTypeDescription
    $objs = Get-ObjectsFromConfig -ObjectType ObjectTypeDescription
    $bindings = Get-ObjectsFromConfig -ObjectType BindingDescription
    $constantSpec = Get-ObjectsFromConfig -ObjectType ConstantSpecifier

    Write-ToCliXml -Objects $attrs -xmlName Attributes 
    Write-ToCliXml -Objects $objs -xmlName ObjectTypes 
    Write-ToCliXml -Objects $bindings -xmlName Bindings
    Write-ToCliXml -Objects $constantSpec -xmlName ConstSpecifiers
}

Function Get-PolicyConfigToXml {
    $mgmntPolicies = Get-ObjectsFromConfig -ObjectType ManagementPolicyRule
    $sets = Get-ObjectsFromConfig -ObjectType Set
    $workflowDef = Get-ObjectsFromConfig -ObjectType WorkflowDefinition
    $emailtmplt = Get-ObjectsFromConfig -ObjectType EmailTemplate
    $filterscope = Get-ObjectsFromConfig -ObjectType FilterScope
    $activityInfo = Get-ObjectsFromConfig -ObjectType ActivityInformationConfiguration
    $funct = Get-ObjectsFromConfig -ObjectType Function
    $syncRule = Get-ObjectsFromConfig -ObjectType SynchronizationRule
    $syncFilter = Get-ObjectsFromConfig -ObjectType SynchronizationFilter

    Write-ToCliXml -Objects $mgmntPolicies -xmlName Policies
    Write-ToCliXml -Objects $sets -xmlName Sets 
    Write-ToCliXml -Objects $workflowDef -xmlName Workflows 
    Write-ToCliXml -Objects $emailtmplt -xmlName EmailTemplates 
    Write-ToCliXml -Objects $filterscope -xmlName FilterScopes 
    Write-ToCliXml -Objects $activityInfo -xmlName ActivityInfo 
    Write-ToCliXml -Objects $funct -xmlName PolicyFunctions
    if ($syncRule) {
        Write-ToCliXml -Objects $syncRule -xmlName SyncRules  
    }
    Write-ToCliXml -Objects $syncFilter -xmlName SyncFilters 
}

Function Get-PortalConfigToXml {
    $portalUI = Get-ObjectsFromConfig -ObjectType PortalUIConfiguration
    $navBar = Get-ObjectsFromConfig -ObjectType NavigationBarConfiguration
    $searchScope = Get-ObjectsFromConfig -ObjectType SearchScopeConfiguration
    $objVisual = Get-ObjectsFromConfig -ObjectType ObjectVisualizationConfiguration
    $homePage = Get-ObjectsFromConfig -ObjectType HomepageConfiguration
    $configuration = Get-ObjectsFromConfig -ObjectType Configuration

    Write-ToCliXml -Objects $portalUI -xmlName PortalUI
    Write-ToCliXml -Objects $navBar -xmlName NavBar 
    Write-ToCliXml -Objects $searchScope -xmlName SearchScope 
    Write-ToCliXml -Objects $objVisual -xmlName ObjectVisual 
    Write-ToCliXml -Objects $homePage -xmlName HomePage
    if($configuration){
        Write-ToCliXml -Objects $configuration -xmlName Configur
    }
}

function Get-ObjectsFromConfig {
    param(
        [Parameter(Mandatory=$True)]
        [String]
        $ObjectType
    )
    $objects = Search-Resources -XPath "/$ObjectType" -ExpectedObjectType $ObjectType
    # Read only members, not needed for import (are generated in the MIM-Setup)
    $illegalMembers = @("CreatedTime", "Creator", "DeletedTime", "DetectedRulesList",
    "ExpectedRulesList", "ResourceTime", "ComputedMember")
    # converts return of Search-Resources to clixml format
    # Source and Destination MIM-Setup get compared with objects that both have been serialized and deserialized
    if ($objects) {
        # Remove read-only attributes
        foreach($obj in $objects){
            foreach($illMem in $illegalMembers){
                $obj.psobject.properties.Remove("$illMem")
            }
        }
        Write-ToCliXml -Objects $objects -xmlName Temp   
        $objects = Import-Clixml "ConfigTemp.xml"
    } else {
        Write-Host "No objects found to write to clixml!"
    }
    return $objects
}

Function Write-ToCliXml {
    param(
        [Parameter(Mandatory=$True)]
        [Array]
        $Objects,

        [Parameter(Mandatory=$True)]
        [String]
        $xmlName
    )
    Export-Clixml -InputObject $Objects -Path "Config$xmlName.xml" -Depth 4 
}

Function Get-ObjectsFromXml {
    param(
        [Parameter(Mandatory=$True)]
        [String]
        $xmlFilePath
    )
    try{
        $objs = Import-Clixml -Path $xmlFilePath
        return $objs
    } catch [System.Management.Automation.ItemNotFoundException] {
        Write-Host "File not found $xmlFilePath" -ForegroundColor Red
    }
}

Function Compare-MimObjects {
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
        Write-Host "`rComparing $Type objects: $i/$total...`t`t" -NoNewline
        $i++
        if ($Anchor.Count -eq 1) {
            $obj2 = $ObjsDestination | Where-Object{$_.($Anchor[0]) -eq $obj.($Anchor[0])}
        } elseif ($Anchor.Count -eq 2) {
            # If the Object has referentials
            if ($Anchor -contains "BoundAttributeType" -and $Anchor -contains "BoundObjectType") {
                # Find the corresponding object that matches the BoundAttributeType ID
                $RefToAttrSrc = $global:ReferentialList.SourceRefAttrs | Where-Object{$_.ObjectID.Value -eq $obj.BoundAttributeType.Value}
                # Find the corresponding object that matches the referenced source attribute with the destination attribute by Name
                $RefToAttrDest = $global:ReferentialList.DestRefAttrs | Where-Object{$_.Name -eq $RefToAttrSrc.Name}

                $RefToObjSrc = $global:ReferentialList.SourceRefObjs | Where-Object{$_.ObjectID.Value -eq $obj.BoundObjectType.Value}
                $RefToObjDest = $global:ReferentialList.DestRefObjs | Where-Object{$_.Name -eq $RefToObjSrc.Name}
                if ($RefToAttrDest -and $RefToObjDest) {
                    #obj2 gets the correct object that corresponds to the source object
                    $obj2 = $ObjsDestination | Where-Object {$_.BoundAttributeType -like $RefToAttrDest.ObjectID -and
                    $_.BoundObjectType -like $RefToObjDest.ObjectID}
                } else {
                    $obj2 = ""
                }
            } else {
                $obj2 = $ObjsDestination | Where-Object {$_.($Anchor[0]) -like $obj.($Anchor[0]) -and 
                $_.($Anchor[1]) -like $obj.($Anchor[1])}
            }
        } else {
            if ($Anchor -contains "BoundAttributeType" -and $Anchor -contains "BoundObjectType") {
                $RefToAttrSrc = $global:ReferentialList.SourceRefAttrs | Where-Object{$_.ObjectID.Value -eq $obj.BoundAttributeType.Value}
                $RefToAttrDest = $global:ReferentialList.DestRefAttrs | Where-Object{$_.Name -eq $RefToAttrSrc.Name}

                $RefToObjSrc = $global:ReferentialList.SourceRefObjs | Where-Object{$_.ObjectID.Value -eq $obj.BoundObjectType.Value}
                $RefTOObjDest = $global:ReferentialList.DestRefObjs | Where-Object{$_.Name -eq $RefToObjSrc.Name}
                if ($RefToAttrDest -and $RefToObjDest) {
                    $obj2 = $ObjsDestination | Where-Object {$_.BoundAttributeType -like $RefToAttrDest.ObjectID -and
                    $_.BoundObjectType -like $RefToObjDest.ObjectID -and $_.($Anchor[2]) -eq $obj.($Anchor[2])}
                } else {
                    $obj2 = ""
                }
            } else {
                $obj2 = $ObjsDestination | Where-Object {$_.($Anchor[0]) -like $obj.($Anchor[0]) -and 
                $_.($Anchor[1]) -like $obj.($Anchor[1]) -and $_.($Anchor[2]) -like $obj.($Anchor[2])}
            }
        }
        # If there is no match between the objects from different sources the object will be added for import
        if (!$obj2) {
            Write-Host "New object found:"
            Write-Host $obj -ForegroundColor yellow
            if ($Anchor -contains "BoundObjectType" -and $Anchor -contains "BoundAttributeType") { 
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
                $compObj = $compResult | Where-Object {$_.SideIndicator -eq '<='} # Difference in source object!
                $resultComp = $compObj | Where-Object membertype -like 'noteproperty'
                $newObj = [PSCustomObject] @{}
                foreach($mem in $resultComp){
                    $newObj | Add-Member -NotePropertyName $mem.Name -NotePropertyValue $Mem.Value
                }
                Write-host "Different object properties found:"
                Write-host $newObj -ForegroundColor Yellow -BackgroundColor Black
                $difference.Add($newObj)
                if ($newObj.psobject.properties.Name -contains "BoundAttributeType" -and 
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
        Write-ToXmlFile -DifferenceObjects $Difference -path $path -Anchor $Anchor
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
    $FileName = "$path\configurationDelta.xml"
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
            # referencing purposes, no need in the attributes themselves
            if ($member.Name -eq "ObjectID") {
                # set the objectID of the object as the id of the xml node
                $XmlOperation.SetAttribute("id", $member.Value.Value)
                continue
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
    Import a delta in a MIM-setup
    
    .DESCRIPTION
    Import the differences between the source MIM setup and the target MIM setup in the target 
    MIM setup using a delta in xml
    
    .PARAMETER DeltaConfigFilePath
    The path to a delta of a configuration in a xml file
    #>
    param (
        [Parameter(Mandatory=$True)]
        [string]
        $DeltaConfigFilePath
    )
        # When Preview is enabled this will not import the configuration but give a preview
        Import-RMConfig $DeltaConfigFilePath -Verbose #-Preview
}