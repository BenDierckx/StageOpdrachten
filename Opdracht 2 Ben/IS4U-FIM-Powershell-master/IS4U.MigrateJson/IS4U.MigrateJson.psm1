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

Function Get-SchemaConfigToJson {
    param(
        [Parameter(Mandatory=$False)]
        [Bool]
        $Source = $False
    )

    $attrs = Get-ObjectsFromConfigg -ObjectType AttributeTypeDescription
    $objs = Get-ObjectsFromConfigg -ObjectType ObjectTypeDescription
    $binds = Get-ObjectsFromConfigg -ObjectType BindingDescription
    $constSpec = Get-ObjectsFromConfigg -ObjectType ConstantSpecifier
    $schemaSup = Get-ObjectsFromConfigg -ObjectType SchemaSupportedLocales

    ConvertTo-Json -Objects $attrs -JsonName Attributes
    ConvertTo-Json -Objects $objs -JsonName objects
    ConvertTo-Json -Objects $binds -JsonName Bindings
    ConvertTo-Json -Objects $constSpec -JsonName ConstantSpecifiers
    ConvertTo-Json -Objects $schemaSup -JsonName SchemaSupportedLocales
}

Function Compare-Schema {
    Write-Host "Starting compare of Schema configuration..."
    # Source of objects to be imported
    $attrsSource = Get-ObjectsFromJson -JsonFilePath "ConfigAttributes.json"
    $objsSource = Get-ObjectsFromJson -JsonFilePath "ConfigObjectTypes.json"
    $bindingsSource = Get-ObjectsFromJson -JsonFilePath "ConfigBindings.json"
    $constSpecsSource = Get-ObjectsFromJson -JsonFilePath "ConfigConstSpecifiers.json"
    $schemaSupsSource = Get-ObjectsFromJson -JsonFilePath "SchemaSupportedLocales.json"
    
    # Target Setup objects, comparing purposes
    $attrsDest = Search-Resources -XPath "/AttributeTypeDescription" -ExpectedObjectType AttributeTypeDescription
    $objsDest = Search-Resources -XPath "/ObjectTypeDescription" -ExpectedObjectType ObjectTypeDescription
    $bindingsDest = Search-Resources -XPath "/BindingDescription" -ExpectedObjectType BindingDescription
    $constSpecsDest = Search-Resources -XPath "/ConstantSpecifier" -ExpectedObjectType ConstantSpecifier
    $schemaSupsDest = Search-Resources -XPath "/SchemaSupportedLocales" -ExpectedObjectType SchemaSupportedLocales

    # Comparing of the Source and Target Setup to create delta xml file
    Compare-Objects -ObjsSource $attrsSource -ObjsDestination $attrsDest
    Compare-Objects -ObjsSource $objsSource -ObjsDestination $objsDest
    Compare-Objects -ObjsSource $bindingsSource -ObjsDestination $bindingsDest
    Compare-Objects -ObjsSource $constSpecsSource -ObjsDestination $constSpecsDest
    Compare-Objects -ObjsSource $schemaSupsSource -ObjsDestination $schemaSupsDest
    Write-Host "Compare of Schema configuration completed."
}

Function Get-PolicyConfigToJson {
    param(
        [Parameter(Mandatory=$False)]
        [Bool]
        $Source = $False
    )

    $manPol = Get-ObjectsFromConfigg -ObjectType ManagementPolicyRule
    $sets = Get-ObjectsFromConfigg -ObjectType Set
    $workFlowDef = Get-ObjectsFromConfigg -ObjectType WorkflowDefinition
    $emailTem = Get-ObjectsFromConfigg -ObjectType EmailTemplate
    $filterScope = Get-ObjectsFromConfigg -ObjectType FilterScope
    $actInfConf = Get-ObjectsFromConfigg -ObjectType ActivityInformationConfiguration
    $function = Get-ObjectsFromConfigg -ObjectType Function
    $syncRule = Get-ObjectsFromConfigg -ObjectType SynchronizationRule
    $syncFilter = Get-ObjectsFromConfigg -ObjectType SynchronizationFilter

    ConvertTo-Json -Objects $manPol -JsonName ManagementPolicyRules
    ConvertTo-Json -Objects $sets -JsonName Sets
    ConvertTo-Json -Objects $workFlowDef -JsonName WorkflowDefinitions
    ConvertTo-Json -Objects $emailTem -JsonName EmailTemplates
    ConvertTo-Json -Objects $filterScope -JsonName FilterScopes
    ConvertTo-Json -Objects $actInfConf -JsonName ActivityInformationConfigurations
    ConvertTo-Json -Objects $function -JsonName Functions
    ConvertTo-Json -Objects $syncRule -JsonName SynchronizationRules
    ConvertTo-Json -Objects $syncFilter -JsonName SynchronizationFilter
}

Function Get-PortalConfigToJson {
    param(
        [Parameter(Mandatory=$False)]
        [Bool]
        $Source = $False
    )

    $homeConf = Get-ObjectsFromConfigg -ObjectType HomepageConfiguration
    $portalUIConf = Get-ObjectsFromConfigg -ObjectType PortalUIConfiguration
    $conf = Get-ObjectsFromConfigg -ObjectType Configuration
    $naviBarConf = Get-ObjectsFromConfigg -ObjectType NavigationBarConfiguration
    $searchScopeConf = Get-ObjectsFromConfigg -ObjectType SearchScopeConfiguration
    $objectVisualConf = Get-ObjectsFromConfigg -ObjectType ObjectVisualizationConfiguration

    ConvertTo-Json -Objects $homeConf -JsonName HomepageConfigurations
    ConvertTo-Json -Objects $portalUIConf -JsonName PortalUIConfigurations
    ConvertTo-Json -Objects $conf -JsonName Configurations
    ConvertTo-Json -Objects $naviBarConf -JsonName NavigationBarConfigurations
    ConvertTo-Json -Objects $searchScopeConf -JsonName SearchScopeConfigurations
    ConvertTo-Json -Objects $objectVisualConf -JsonName ObjectVisualizationConfigurations
}

Function Get-ObjectsFromConfig {
    param(
        [Parameter(Mandatory=$True)]
        [String]
        $ObjectType
    )
    # This looks for objectTypes and expects objects with the type ObjectType
    $objects = Search-Resources -Xpath "/$ObjectType" -ExpectedObjectType $ObjectType
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
    $Objects | ConvertTo-Json | Out-File "./Json$JsonName.json"      # "./IS4U.MigrateTest"
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