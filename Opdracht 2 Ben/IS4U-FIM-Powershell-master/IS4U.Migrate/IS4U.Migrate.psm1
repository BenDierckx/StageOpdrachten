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

<#
    ToDo:   * Global variabelen om objectid's op te slagen (voor referenties)
            * Referenties linken aan globale variabele voor de 2 omgevingen
            * Testen in omgeving met elke type
            * (objectid als anchors gebruiken)
    Nog te beschrijven: Alleen deze module gebruiken door een Powershell prompt te openen in dezelfde folder aan beide kanten!!
#>

#region Lithnet
if(!(Get-Module -Name LithnetRMA))
{
Import-Module LithnetRMA;
}
#Set-ResourceManagementClient -BaseAddress http://localhost:5725;
#endregion Lithnet

Function Start-Migration {
    param(
        [Parameter(Mandatory=$False)]
        [Bool]
        $SourceOfMIMSetup = $False,
        
        [Parameter(Mandatory=$False)]
        [Bool]
        $ImportAllConfigurations = $true,
        
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

    $global:ReferentialList = @{SourceRefObjs = [System.Collections.ArrayList]@(); $DestRefObjs = [System.Collections.ArrayList]@()}

    if ($SourceOfMIMSetup) {
        Get-SchemaConfigToXml
        Get-PortalConfigToXml
        Get-PolicyConfigToXml
    } else {
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
                Compare-Policy -path $path
            }
            if ($ImportPortal) {
                Compare-Portal -path $path
            }
        }
        Remove-Variable -Name $global:ReferentialList
        if (Test-Path -Path "$path/ConfigurationDelta.xml") {
            Import-Delta -DeltaConfigFilePath "$path/ConfigurationDelta.xml"
        } else {
            Write-Host "No ConfigurationDelta file found: Not created or no differences found!"
        }
    }
}

Function Compare-Schema {
    param(
        [Parameter(Mandatory=$True)]
        [String]
        $Path
    )
    Write-Host "Starting compare of Schema configuration..."
    # Source of objects to be imported
    $attrsSource = Get-ObjectsFromXml -XmlFilePath "ConfigAttributes.xml"
    $objsSource = Get-ObjectsFromXml -XmlFilePath "ConfigObjectTypes.xml"
    $bindingsSource = Get-ObjectsFromXml -XmlFilePath "ConfigBindings.xml"
    $cstspecifiersSource = Get-ObjectsFromXml -XmlFilePath "ConfigConstSpecifiers.xml"
    
    # Target Setup objects, comparing purposes
    #$attrsDest = Search-Resources -XPath "/AttributeTypeDescription" -ExpectedObjectType AttributeTypeDescription
    #$objsDest = Search-Resources -XPath "/ObjectTypeDescription" -ExpectedObjectType ObjectTypeDescription
    #$bindingsDest = Search-Resources -XPath "/BindingDescription" -ExpectedObjectType BindingDescription
    #$cstspecifiersDest = Search-Resources -XPath "/ConstantSpecifier" -ExpectedObjectType ConstantSpecifier
    $attrsDest = Get-ObjectsFromConfig -ObjectType AttributeTypeDescription
    $objsDest = Get-ObjectsFromConfig -ObjectType ObjectTypeDescription
    $bindingsDest = Get-ObjectsFromConfig -ObjectType BindingDescription
    $cstspecifiersDest = Get-ObjectsFromConfig -ObjectType ConstantSpecifier

    # Comparing of the Source and Target Setup to create delta xml file
    Write-Host "0%..."
    Compare-MimObjects -ObjsSource $attrsSource -ObjsDestination $attrsDest -path $path
    Write-Host "25%..."
    Compare-MimObjects -ObjsSource $objsSource -ObjsDestination $objsDest -path $path
    Write-Host "50%..."
    Compare-MimObjects -ObjsSource $bindingsSource -ObjsDestination $bindingsDest -Anchor @("BoundAttributeType", "BoundObjectType") -path $path
    Write-Host "75%..."
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
    Write-Host "Starting compare of Policy configuration..."
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
    Write-Host "0%..."
    Compare-MimObjects -ObjsSource $mgmntPlciesSrc -ObjsDestination $mgmntPlciesDest -Anchor @("DisplayName") -path $path
    Write-Host "11.1%..."
    Compare-MimObjects -ObjsSource $setsSrc -ObjsDestination $setsDest -Anchor @("DisplayName") -path $path
    Write-Host "22.2%..."
    Compare-MimObjects -ObjsSource $workflowSrc -ObjsDestination $workflowDest -Anchor @("DisplayName") -path $path
    Write-Host "33.2%..."
    Compare-MimObjects -ObjsSource $emailSrc -ObjsDestination $emailDest -Anchor @("DisplayName") -path $path
    Write-Host "44.4%..."
    Compare-MimObjects -ObjsSource $filtersSrc -ObjsDestination $filtersDest -Anchor @("DisplayName") -path $path
    Write-Host "55.5%..."
    Compare-MimObjects -ObjsSource $activitySrc -ObjsDestination $activityDest -Anchor @("DisplayName") -path $path
    Write-Host "66.6%..."
    Compare-MimObjects -ObjsSource $funcSrc -ObjsDestination $funcDest -Anchor @("DisplayName") -path $path
    Write-Host "77.7%..."
    if ($syncRSrc) {
    Compare-MimObjects -ObjsSource $syncRSrc -ObjsDestination $syncRDest -Anchor @("DisplayName") -path $path
    Write-Host "88.8%..."
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
    Write-Host "Starting compare of Portal configuration..."
    # Source of objects to be imported
    $UISrc = Get-ObjectsFromXml -xmlFilePath "ConfigPortalUI.xml"
    $navSrc = Get-ObjectsFromXml -xmlFilePath "ConfigNavBar.xml"
    $srchScopeSrc = Get-ObjectsFromXml -xmlFilePath "ConfigSearchScope.xml"
    $objVisSrc = Get-ObjectsFromXml -xmlFilePath "ConfigObjectVisual.xml"
    $homePSrc = Get-ObjectsFromXml -xmlFilePath "ConfigHomePage.xml"
    $configSrc = Get-ObjectsFromXml -xmlFilePath "ConfigConfigur.xml"

    # Target Setup objects, comparing purposes
    <#$UIDest = Search-Resources -XPath "/PortalUIConfiguration" -ExpectedObjectType PortalUIConfiguration
    $navDest = Search-Resources -XPath "/NavigationBarConfiguration" -ExpectedObjectType NavigationBarConfiguration
    $srchScopeDest = Search-Resources -XPath "/SearchScopeConfiguration" -ExpectedObjectType SearchScopeConfiguration
    $objVisDest = Search-Resources -XPath "/ObjectVisualizationConfiguration" -ExpectedObjectType ObjectVisualizationConfiguration
    $homePDest = Search-Resources -XPath "/HomepageConfiguration" -ExpectedObjectType HomepageConfiguration
    $configDest = Search-Resources -XPath "/Configuration" -ExpectedObjectType Configuration#>
    $UIDest = Get-ObjectsFromConfig -ObjectType PortalUIConfiguration
    $navDest = Get-ObjectsFromConfig -ObjectType NavigationBarConfiguration
    $srchScopeDest = Get-ObjectsFromConfig -ObjectType SearchScopeConfiguration
    $objVisDest = Get-ObjectsFromConfig -ObjectType ObjectVisualizationConfiguration
    $homePDest = Get-ObjectsFromConfig -ObjectType HomepageConfiguration
    $configDest = Get-ObjectsFromConfig -ObjectType Configuration

    # Comparing of the Source and Target Setup to create delta xml file
    Write-Host "0%..."
    Compare-MimObjects -ObjsSource $UISrc -ObjsDestination $UIDest -Anchor @("DisplayName") -path $path
    Write-Host "16.6%..."
    Compare-MimObjects -ObjsSource $navSrc -ObjsDestination $navDest -Anchor @("DisplayName") -path $path
    Write-Host "33.2%..."
    Compare-MimObjects -ObjsSource $srchScopeSrc -ObjsDestination $srchScopeDest -Anchor @("DisplayName", "Order") -path $path
    Write-Host "49.8%..."
    Compare-MimObjects -ObjsSource $objVisSrc -ObjsDestination $objVisDest -Anchor @("DisplayName") -path $path
    Write-Host "66.4%..."
    Compare-MimObjects -ObjsSource $homePSrc -ObjsDestination $homePDest -Anchor @("DisplayName") -path $path
    Write-Host "83%..."
    if ($configSrc -and $configDest) {
        Compare-MimObjects -ObjsSource $configSrc -ObjsDestination $configDest -Anchor @("DisplayName") -path $path # Can be empty
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
    # converts return of search-resources to clixml format
    # Compare had troubles because of different types after serialize
    # Source and Destination MIM-Setup get compared with objects that both have been serialized and deserialized
    if ($objects) {
        Write-ToCliXml -Objects $objects -xmlName Temp   
        $objects = Import-Clixml "ConfigTemp.xml"
    } else {
        #$objects | Export-Clixml -Path "tempConfig.xml" -Depth 4
        Write-Host "No objects found to write to clixml!"
    }
    foreach($obj in $objects) {
        if ($obj.ObjectType -eq "AttributeTypeDescription" -or $obj.ObjectType -eq "ObjectTypeDescription") {
            $global:ReferentialList.DestRefObjs.Add($obj)
        }
    }
    return $objects
}

# Csv problem: Arrays in the PsCustomObjects do not get the required depth
# CliXml problems: Array of 1 object gets serialized to string
#                  AttributeValueArrayList gets deserialized to ArrayList from xml
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
    $objs = Import-Clixml -Path $xmlFilePath
    foreach($obj in $objs) {
        if ($obj.ObjectType -eq "AttributeTypeDescription" -or $obj.ObjectType -eq "ObjectTypeDescription") {
            $global:ReferentialList.SourceRefObjs.Add($obj)
        }
    }
    return $objs
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
    $difference = [System.Collections.ArrayList] @()
    foreach ($obj in $ObjsSource){
        if ($Anchor.Count -eq 1) {
            $obj2 = $ObjsDestination | Where-Object{$_.($Anchor[0]) -eq $obj.($Anchor[0])}
        } elseif ($Anchor.Count -eq 2) {
            if ($Anchor -contains "BoundAttributeType" -and $Anchor -contains "BoundObjectType") {
                # Get corresponding object from the source (xml files). Search on ObjectID
                $RefToAttrSrc = $global:ReferentialList.SourceRefObjs | Where-Object{$_.ObjectID -eq $obj.BoundAttributeType}
                # Get-Resource for corresponding object from the target Schema
                $RefToAttrDest = Get-Resource -ObjectType AttributeTypeDescription -AttributeName Name -AttributeValue $RefToAttrSrc.Name
                # Get the object from the target schema
                #$RefToAttrDest = $global:ReferentialList.DestRefObjs | Where-Object{$_.ObjectID -eq $TempAttrDest.BoundAttributeType}

                $refToObjSrc = $global:ReferentialList.SourceRefObjs | Where-Object{$_.ObjectID -eq $obj.BoundObjectType}
                $RefToObjDest = Get-Resource -ObjectType ObjectTypeDescription -AttributeName Name -AttributeValue $refToObjSrc.Name
                #$refToObjDest = $global:ReferentialList | Where-Object{$_.ObjectID -eq $TempObjDest.BoundObjectType}
                
                $obj2 = $ObjsDestination | Where-Object {$_.BoundAttributeType -like $RefToAttrDest.BoundAttributeType -and 
                $_.BoundObjectType -like $RefToObjDest.BoundObjectType}
            } else {
                $obj2 = $ObjsDestination | Where-Object {$_.($Anchor[0]) -like $obj.($Anchor[0]) -and
                $_.($Anchor[1]) -like $obj.($Anchor[1])}   
            }
        } else {
            if ($Anchor -contains "BoundAttributeType" -and $Anchor -contains "BoundObjectType") {
                $RefToAttrSrc = $global:ReferentialList.SourceRefObjs | Where-Object{$_.ObjectID -eq $obj.BoundAttributeType}
                $RefToAttrDest = Get-Resource -ObjectType AttributeTypeDescription -AttributeName Name -AttributeValue $RefToAttrSrc.Name
                #$RefToAttrDest = $global:ReferentialList.DestRefObjs | Where-Object{$_.ObjectID -eq $TempAttrDest.BoundAttributeType}

                $refToObjSrc = $global:ReferentialList.SourceRefObjs | Where-Object{$_.ObjectID -eq $obj.BoundObjectType}
                $RefToObjDest = Get-Resource -ObjectType ObjectTypeDescription -AttributeName Name -AttributeValue $refToObjSrc.Name
                #$RefToObjDest = $global:ReferentialList | Where-Object{$_.ObjectID -eq $TempObjDest.BoundObjectType}
                
                $obj2 = $ObjsDestination | Where-Object {$_.BoundAttributeType -like $RefToAttrDest.BoundAttributeType -and
                $_.BoundObjectType -like $RefToObjDest.BoundObjectType -and $_.($Anchor[2]) -eq $obj.($Anchor[2])}
            } else {
                $obj2 = $ObjsDestination | Where-Object {$_.($Anchor[0]) -like $obj.($Anchor[0]) -and
                $_.($Anchor[1]) -like $obj.($Anchor[1]) -and $_.($Anchor[2]) -eq $obj.($Anchor[2])}
            }
        }
        if (!$obj2) {
            Write-Host "New object found:"
            Write-Host $obj -ForegroundColor yellow
            $difference.Add($obj)
        } else {
            # remove ObjectID's in case they are different
            #$ReferenceObject = $False
            #$objObjectID = $obj2.ObjectID # ?
            # Alter the original ObjectID to match the target ObjectID
            $obj.psobject.properties.Remove("ObjectID")
            $obj | Add-Member -NotePropertyName ObjectID -NotePropertyValue $obj2.ObjectID
            # Use id's from target configuration ...
            if ($obj.psobject.properties.Members.Value.Name -contains "BoundAttributeType" -and
            $obj.psobject.properties.Members.Value.Name -contains "BoundObjectType") {
                $obj.psobject.properties.remove("BoundAttributeType")
                $obj.psobject.properties.remove("BoundObjectType")
                obj | Add-Member -NotePropertyName BoundAttributeType -NotePropertyValue $obj2.BoundAttributeType
                obj | Add-Member -NotePropertyName BoundObjectType -NotePropertyValue $obj2.BoundObjectType
                #$obj2.psobject.properties.remove("BoundAttributeType")
                #$obj2.psobject.properties.remove("BoundObjectType")
                #$ReferenceObject = $True
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
                #$newObj | Add-Member -NotePropertyName "ObjectID" -NotePropertyValue $objObjectID 
                <#if ($ReferenceObject) {
                    $newObj | Add-Member -NotePropertyName "BoundAttributeType" -NotePropertyValue ""
                    $newObj | Add-Member -NotePropertyName "BoundObjectType" -NotePropertyValue ""
                }#>
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
            # Different anchors for Bindings (referentials)
        if ($obj.ObjectType -eq "BindingDescription") {
            $xmlElement1 = $XmlDoc.CreateElement("AnchorAttribute")
            $xmlElement1.Set_InnerText("BoundAttributeType")
            $xmlElement2 = $XmlDoc.CreateElement("AnchorAttribute")
            $xmlElement2.Set_InnerText("BoundObjectType")
            $XmlAnchors.AppendChild($xmlElement1)
            $XmlAnchors.AppendChild($xmlElement2)
        } else {
            foreach($anch in $Anchor){
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
            # Attributes that are read only do not get implemented in the xml file
            $illegalMembers = @("ObjectType", "CreatedTime", "Creator", "DeletedTime", "DetectedRulesList",
             "ExpectedRulesList", "ResourceTime", "ComputedMember")
            # Skip read only attributes and ObjectType (already used in ResourceOperation)
            if ($illegalMembers -contains $member.Name) { continue }
            if($member.Value){
                if ($member.Value.GetType().BaseType.Name -eq "Array") {  ## aangepast, beziet altijd of het array is of niet
                    foreach ($m in $member.Value) {
                        $xmlVarElement = $XmlDoc.CreateElement("AttributeOperation")
                        $xmlVarElement.Set_InnerText($m)
                        $xmlVariable = $XmlAttributes.AppendChild($xmlVarElement)
                        $xmlVariable.SetAttribute("operation", "add") # add because we don't want to replace the items 
                        $xmlVariable.SetAttribute("name", $member.Name)
                    }
                    continue    # Rest is not needed after array
                }
            }
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

# Voor zelf folder te laten selecteren
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