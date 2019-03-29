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

Function Start-MigrationJson {
    param(
        # Source?
        [Parameter(Mandatory=$False)]
        [Bool]
        $SourceOfMIMSetup = $False,
        
        [Parameter(Mandatory=$False)]
        [Bool]
        $ImportAllConfigurations = $true,
        
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

    $Global:ReferentialList = @{SourceRefAttrs = [System.Collections.ArrayList]@(); DestRefAttrs = [System.Collections.ArrayList]@() 
    SourceRefObjs = [System.Collections.ArrayList]@(); DestRefObjs = [System.Collections.ArrayList]@();}

    if ($SourceOfMIMSetup) {
        Get-SchemaConfigToJson
        Get-PortalConfigToJson
        Get-PolicyConfigToJson
    } else {
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
                Compare-Policy -path $path
            }
            if ($ImportPortal) {
                Compare-Portal -path $path
            }
        }
        Remove-Variable ReferentialList
        if (Test-Path -Path "$path/ConfigurationDelta.json") {
            Import-Delta -DeltaConfigFilePath "$path/ConfigurationDelta.json"
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
    #$schemaSup = Get-ObjectsFromConfig -ObjectType SchemaSupportedLocales

    Convert-ToJson -Objects $attrs -JsonName Attributes
    Convert-ToJson -Objects $objs -JsonName objectTypes
    Convert-ToJson -Objects $binds -JsonName Bindings
    Convert-ToJson -Objects $constSpec -JsonName ConstantSpecifiers
    #Convert-ToJson -Objects $schemaSup -JsonName SchemaSupportedLocales
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
        $Global:ReferentialList.SourceRefAttrs.Add($obj)
    }
    $objsSource = Get-ObjectsFromJson -JsonFilePath "ConfigObjectTypes.json"
    foreach($obj in $objsSource) {
        $Global:ReferentialList.SourceRefObjs.Add($obj)
    }
    $bindingsSource = Get-ObjectsFromJson -JsonFilePath "ConfigBindings.json"
    $constSpecsSource = Get-ObjectsFromJson -JsonFilePath "ConfigConstSpecifiers.json"
    #$schemaSupsSource = Get-ObjectsFromJson -JsonFilePath "SchemaSupportedLocales.json"
    
    # Target Setup objects, comparing purposes
    #$attrsDest = Search-Resources -XPath "/AttributeTypeDescription" -ExpectedObjectType AttributeTypeDescription
    #$objsDest = Search-Resources -XPath "/ObjectTypeDescription" -ExpectedObjectType ObjectTypeDescription
    #$bindingsDest = Search-Resources -XPath "/BindingDescription" -ExpectedObjectType BindingDescription
    #$constSpecsDest = Search-Resources -XPath "/ConstantSpecifier" -ExpectedObjectType ConstantSpecifier
    #$schemaSupsDest = Search-Resources -XPath "/SchemaSupportedLocales" -ExpectedObjectType SchemaSupportedLocales

    # Makes target a json and then converts it to an object
    $attrsDest = Get-ObjectsFromConfig -ObjectType AttributeTypeDescription
    foreach($obj in $attrsDest) {
        $Global:ReferentialList.DestRefAttrs.Add($obj)
    }
    $objsDest = Get-ObjectsFromConfig -ObjectType ObjectTypeDescription
    foreach($obj in $objsDest) {
        $Global:ReferentialList.DestRefObjs.Add($obj)
    }
    $bindingsDest = Get-ObjectsFromConfig -ObjectType BindingDescription
    $constSpecsDest = Get-ObjectsFromConfig -ObjectType ConstantSpecifier

    # Comparing of the Source and Target Setup to create delta xml file
    Write-Host "0%"
    Compare-Objects -ObjsSource $attrsSource -ObjsDestination $attrsDest -path $path
    Write-Host "25%"
    Compare-Objects -ObjsSource $objsSource -ObjsDestination $objsDest -path $path
    Write-Host "50%"
    Compare-Objects -ObjsSource $bindingsSource -ObjsDestination $bindingsDest -Anchor @("BoundAttributeType", "BoundObjectType") -path $path
    Write-Host "75%"
    Compare-Objects -ObjsSource $constSpecsSource -ObjsDestination $constSpecsDest -Anchor @("BoundAttributeType", "BoundObjectType", "ConstantValueKey") -path $path
    #Compare-Objects -ObjsSource $schemaSupsSource -ObjsDestination $schemaSupsDest
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
    Convert-ToJson -Objects $syncFilter -JsonName SynchronizationFilter
}

Function Compare-PolicyJson {
    param(
        [Parameter(Mandatory=$True)]
        [String]
        $path
    )
    Write-Host "Starting compare of Policy configuration..."
    # Source of objects to be imported
    $mgmntPlciesSrc = Get-ObjectsFromJson -JsonFilePath "ConfigPolicies.json"
    $setsSrc = Get-ObjectsFromJson -JsonFilePath "ConfigSets.json"
    $workflowSrc = Get-ObjectsFromJson -JsonFilePath "ConfigWorkflows.json"
    $emailSrc = Get-ObjectsFromJson -JsonFilePath "ConfigEmailTemplates.json"
    $filtersSrc = Get-ObjectsFromJson -JsonFilePath "ConfigFilterScopes.json"
    $activitySrc = Get-ObjectsFromJson -JsonFilePath "ConfigActivityInfo.json"
    $funcSrc = Get-ObjectsFromJson -JsonFilePath "ConfigPolicyFunctions.json"
    $syncRSrc = Get-ObjectsFromJson -JsonFilePath "ConfigSyncRules.json"
    $syncFSrc = Get-ObjectsFromJson -JsonFilePath "ConfigSyncFilters.json"

    # Target Setup objects, comparing purposes
    <#$mgmntPlciesDest = Search-Resources -XPath "/ManagementPolicyRule" -ExpectedObjectType ManagementPolicyRule
    $setsDest = Search-Resources -XPath "/Set" -ExpectedObjectType Set
    $workflowDest = Search-Resources -XPath "/WorkflowDefinition" -ExpectedObjectType WorkflowDefinition
    $emailDest = Search-Resources -XPath "/EmailTemplate" -ExpectedObjectType EmailTemplate
    $filtersDest = Search-Resources -XPath "/FilterScope" -ExpectedObjectType FilterScope
    $activityDest = Search-Resources -XPath "/ActivityInformationConfiguration" -ExpectedObjectType ActivityInformationConfiguration
    $funcDest = Search-Resources -XPath "/Function" -ExpectedObjectType Function 
    $syncRDest = Search-Resources -XPath "/SynchronizationRule" -ExpectedObjectType SynchronizationRule
    $syncFDest = Search-Resources -XPath "/SynchronizationFilter" -ExpectedObjectType SynchronizationFilter#>

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
    Write-Host "0%"
    Compare-Objects -ObjsSource $mgmntPlciesSrc -ObjsDestination $mgmntPlciesDest -Anchor @("DisplayName") -path $path
    Write-Host "11%"
    Compare-Objects -ObjsSource $setsSrc -ObjsDestination $setsDest -Anchor @("DisplayName") -path $path
    Write-Host "22%"
    Compare-Objects -ObjsSource $workflowSrc -ObjsDestination $workflowDest -Anchor @("DisplayName") -path $path
    Write-Host "33%"
    Compare-Objects -ObjsSource $emailSrc -ObjsDestination $emailDest -Anchor @("DisplayName") -path $path
    Write-Host "44%"
    Compare-Objects -ObjsSource $filtersSrc -ObjsDestination $filtersDest -Anchor @("DisplayName") -path $path
    Write-Host "55%"
    Compare-Objects -ObjsSource $activitySrc -ObjsDestination $activityDest -Anchor @("DisplayName") -path $path
    Write-Host "66%"
    Compare-Objects -ObjsSource $funcSrc -ObjsDestination $funcDest -Anchor @("DisplayName") -path $path
    Write-Host "77%"
    if ($syncRSrc) {
        Compare-Objects -ObjsSource $syncRSrc -ObjsDestination $syncRDest -Anchor @("DisplayName") -path $path
        Write-Host "88%"
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
    $UISrc = Get-ObjectsFromJson -JsonFilePath "ConfigPortalUI.json"
    $navSrc = Get-ObjectsFromJson -JsonFilePath "ConfigNavBar.json"
    $srchScopeSrc = Get-ObjectsFromJson -JsonFilePath "ConfigSearchScope.json"
    $objVisSrc = Get-ObjectsFromJson -JsonFilePath "ConfigObjectVisual.json"
    $homePSrc = Get-ObjectsFromJson -JsonFilePath "ConfigHomePage.json"
    $confSrc = Get-ObjectsFromJson -JsonFilePath "ConfigConfigurations"

    # Target Setup objects, comparing purposes
    <#$UIDest = Search-Resources -XPath "/PortalUIConfiguration" -ExpectedObjectType PortalUIConfiguration
    $navDest = Search-Resources -XPath "/NavigationBarConfiguration" -ExpectedObjectType NavigationBarConfiguration
    $srchScopeDest = Search-Resources -XPath "/SearchScopeConfiguration" -ExpectedObjectType SearchScopeConfiguration
    $objVisDest = Search-Resources -XPath "/ObjectVisualizationConfiguration" -ExpectedObjectType ObjectVisualizationConfiguration
    $homePDest = Search-Resources -XPath "/HomepageConfiguration" -ExpectedObjectType HomepageConfiguration#>

    $UIDest = Get-ObjectsFromConfig -ObjectType PortalUIConfiguration
    $navDest = Get-ObjectsFromConfig -ObjectType NavigationBarConfiguration
    $srchScopeDest = Get-ObjectsFromConfig -ObjectType SearchScopeConfiguration
    $objVisDest = Get-ObjectsFromConfig -ObjectType ObjectVisualizationConfiguration
    $homePDest = Get-ObjectsFromConfig -ObjectType HomepageConfiguration
    $confDest = Get-ObjectsFromConfig -ObjectType Configuration

    # Comparing of the Source and Target Setup to create delta xml file
    Write-Host "0%..."
    Compare-Objects -ObjsSource $UISrc -ObjsDestination $UIDest -Anchor @("DisplayName") -path $path
    Write-Host "16%"
    Compare-Objects -ObjsSource $navSrc -ObjsDestination $navDest -Anchor @("DisplayName") -path $path
    Write-Host "32%"
    Compare-Objects -ObjsSource $srchScopeSrc -ObjsDestination $srchScopeDest -Anchor @("DisplayName", "Order") -path $path
    Write-Host "50%"
    Compare-Objects -ObjsSource $objVisSrc -ObjsDestination $objVisDest -Anchor @("DisplayName") -path $path
    Write-Host "67%"
    Compare-Objects -ObjsSource $homePSrc -ObjsDestination $homePDest -Anchor @("DisplayName") -path $path
    Write-Host "83%"
    if ($confSrc -and $confDest) {
        Compare-MimObjects -ObjsSource $confSrc -ObjsDestination $confDest -Anchor @("DisplayName") -path $path # Can be empty
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
    # Makes target a json and then converts it to an object
    #$updatedObjs = ConvertTo-Json -InputObject $objects -Depth 4
    #$object = ConvertFrom-Json -InputObject $updatedObjs
    if ($objects) {
        Convert-ToJson -Objects $objects -JsonName Temp
        $objects = ConvertFrom-Json "ConfigTemp.json"
    } else {
        Write-Host "No objects found to write to json"
    }
    return $object
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

    $objs = Get-Content $JsonFilePath | ConvertFrom-Json
    return $objs
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
        Write-Host "Comparing ($i/$total)"
        $i++
        if ($Anchor.Count -eq 1) {
            $obj2 = $ObjsDestination | Where-Object{$_.($Anchor[0]) -eq $obj.($Anchor[0])}
        } elseif ($Anchor.Count -eq 2) { # When ObjectType is BindingDescription or needs two anchors to find one object
            if ($Anchor -contains "BoundAttributeType" -and $Anchor -contains "BoundObjectType") {
                $RefToAttrSrc = $Global:ReferentialList.SourceRefAttrs | Where-Object{$_.ObjectID.Value -eq $obj.BoundAttributeType.Value}
                $RefToAttrDest = $Global:ReferentialList.DestRefAttrs | Where-Object{$_.Name -eq $RefToAttrSrc.Name}

                $RefToObjSrc = $Global:ReferentialList.SourceRefObjs | Where-Object{$_.ObjectID.Value -eq $obj.BoundObjectType.Value}
                $RefToObjDest = $Global:ReferentialList.DestRefObjs | Where-Object{$_.Name -eq $RefToObjSrc.Name}

                $obj2 = $ObjsDestination | Where-Object {$_.BoundAttributeType -like $RefToAttrDest.ObjectID -and 
                $_.BoundObjectType -like $RefToObjDest.ObjectID}
            } else {
                $obj2 = $ObjsDestination | Where-Object {$_.($Anchor[0]) -like $obj.($Anchor[0]) -and `
                $_.($Anchor[1]) -like $obj.($Anchor[1])}
            }
        } else {    # When ObjectType needs multiple anchors to find unique object
            if ($Anchor -contains "BoundAttributeType" -and $Anchor -contains "BoundObjectType") {
                $RefToAttrSrc = $Global:ReferentialList.SourceRefAttrs | Where-Object{$_.ObjectID.Value -eq $obj.BoundAttributeType.Value}
                $RefToAttrDest = $Global:ReferentialList.DestRefAttrs | Where-Object{$_.Name -eq $RefToAttrSrc.Name}

                $RefToObjSrc = $Global:ReferentialList.SourceRefObjs | Where-Object{$_.ObjectID.Value -eq $obj.BoundObjectType.Name}
                $RefToObjDest = $Global:ReferentialList.DestRefObjs | Where-Object{$_.Name -eq $RefToObjSrc.Name}

                $obj2 = $ObjsDestination | Where-Object {$_.BoundAttributeType -like $RefToAttrDest.ObjectID -and 
                $_.BoundObjectType -like $RefToObjDest.ObjectID -and $_.($Anchor[2]) -eq $obj.($Anchor[2])}
            } else {
                $obj2 = $ObjsDestination | Where-Object {$_.($Anchor[0]) -like $obj.($Anchor[0]) -and `
                $_.($Anchor[1]) -like $obj.($Anchor[1]) -and $_.($Anchor[2]) -eq $obj.($Anchor[2])}
            }
        }
        if (!$obj2) {
            Write-Host "New object found:"
            Write-Host $obj -ForegroundColor yellow
            $difference.Add($obj)
        } else {
            $obj.ObjectID = $obj2.ObjectID

            if ($Anchor -contains "BoundAttributeType" -and $Anchor -contains "BoundObjectType") {
                $obj.BoundAttributeType = $obj2.BoundAttributeType
                $obj.BoundObjectType = $obj2.BoundObjectType
            }
            
            $compResult = Compare-Object -ReferenceObject $obj.psobject.members -DifferenceObject $obj2.psobject.members -PassThru
            if ($compResult) {
                Write-Host $obj -BackgroundColor Green -ForegroundColor Black
                Write-Host $obj2 -BackgroundColor White -ForegroundColor Black
                $compObj = $compResult | Where-Object {$_.SideIndicator -eq '<='} # Difference in original!
                $compObj = $compObj | Where-Object membertype -like 'noteproperty'
                $newObj = [PsCustomObject] @{}
                foreach($prop in $compObj){
                    $newobj | Add-Member -NotePropertyName $prop.Name -NotePropertyValue $prop.Value
                }
                Write-host "Different object properties found:"
                Write-host $newObj -ForegroundColor Yellow -BackgroundColor Black
                # Give ObjectID back to the object difference
                $newObj | Add-Member -NotePropertyName "ObjectID" -NotePropertyValue $objObjectID 
                $difference.Add($newObj)
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

        [Parameter(Mandatory=$False)]
        [Array]
        $Anchor,

        [Parameter(Mandatory = $True)]
        [String]
        $path
    )
    # Inititalization xml file
    $FileName = "$path/configurationDelta.xml"
    # Create empty starting lithnet configuration xml file
    if (!(Test-Path -Path $FileName)) {
        [xml]$Doc = New-Object System.Xml.XmlDocument
        $initalElement = $Doc.CreateElement("Lithnet.ResourceManagement.ConfigSync")
        $operationsElement = $Doc.CreateElement("Operations")
        $declaration = $Doc.CreateXmlDeclaration("1.0","UTF-8",$null)
        $Doc.AppendChild($declaration)
        $startNode = $Doc.AppendChild($initalElement)
        $startNode.AppendChild($operationsElement)
        $Doc.Save($FileName)
    }
    if (!(Test-Path -Path $FileName)) {
        Write-Host "File not found"
        break
    }
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
        } else {
            foreach($anch in $Anchor) {
                $xmlElement = $XmlDoc.CreateElement("AnchorAttribute")
                $xmlElement.Set_InnerText($anch)
                $XmlAnchors.AppendChild($xmlElement)
            }
        }
        # Attributes of the object
        $xmlEle = $XmlDoc.CreateElement("AttributeOperations")
        $XmlAttributes = $XmlOperation.AppendChild($xmlEle)
        # Get the PsCustomObject members from the MIM service without the hidden/extra members
        $objMembers = $obj.psobject.Members | Where-Object membertype -like 'noteproperty'
        # iterate over the PsCustomObject members and append them to the AttributeOperations element
        foreach ($member in $objMembers) {
            if($member.Value){
                if ($member.Value.GetType().BaseType.Name -eq "Array") {  ## aangepast, beziet altijd of het array is of niet
                    foreach ($m in $member.Value) {
                        $xmlVarElement = $XmlDoc.CreateElement("AttributeOperation")
                        $xmlVarElement.Set_InnerText($m)
                        $xmlVariable = $XmlAttributes.AppendChild($xmlVarElement)
                        $xmlVariable.SetAttribute("operation", "add") # add because we don't want to replace the items 
                        $xmlVariable.SetAttribute("name", $member.Name)
                    }
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
                $XmlOperation.SetAttribute("id", $member.Value.Value)
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
    # Save the xml 
    $XmlDoc.Save($FileName) #path nog na te zien!!!!!!!!!!!
    # Confirmation
    Write-Host "Written differences in objects to the delta xml file (ConfiurationDelta.xml)"
    # Return the new xml 
    #[xml]$result = $XmlDoc | Select-Xml -XPath "//ResourceOperation[@resourceType='$ObjectType']"
    #[xml]$result = [System.Xml.XmlDocument] (Get-Content ".\$ObjectType.xml")
    #return $result
}

# Voor zelf folder te laten selecteren?
# bron: https://stackoverflow.com/questions/11412617/get-a-folder-path-from-the-explorer-menu-to-a-powershell-variable
Function Select-FolderDialog{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null     

    $objForm = New-Object System.Windows.Forms.FolderBrowserDialog
    $objForm.Rootfolder = "Desktop"
    $objForm.Description = "Select folder to save the ConfigurationDelta.xml"
    $Show = $objForm.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true }))
    If ($Show -eq "OK") {
        Return $objForm.SelectedPath
    } Else {
        Write-Error "Operation cancelled by user."
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