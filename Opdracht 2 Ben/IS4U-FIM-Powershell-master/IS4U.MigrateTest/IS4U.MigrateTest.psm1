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

Function Get-SchemaConfigg {
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

Function Get-PolicyConfigg {
    param(
        [Parameter(Mandatory=$False)]
        [Bool]
        $Source = $False
    )

    $manPol = Get-ObjectsFromConfigg -ObjectType ManagementPolicyRule
    $sets = Get-ObjectsFromConfigg -ObjectType Set
    $workFlowDefs = Get-ObjectsFromConfigg -ObjectType WorkflowDefinition
    $emailTems = Get-ObjectsFromConfigg -ObjectType EmailTemplate
    $filterScopes = Get-ObjectsFromConfigg -ObjectType FilterScope
    $actInfConfs = Get-ObjectsFromConfigg -ObjectType ActivityInformationConfiguration
    $functions = Get-ObjectsFromConfigg -ObjectType Function
    $syncRules = Get-ObjectsFromConfigg -ObjectType SynchronizationRule
    $syncFilters = Get-ObjectsFromConfigg -ObjectType SynchronizationFilter

    ConvertTo-Json -Objects $manPol -JsonName ManagementPolicyRules
    ConvertTo-Json -Objects $sets -JsonName Sets
    ConvertTo-Json -Objects $workFlowDefs -JsonName WorkflowDefinitions
    ConvertTo-Json -Objects $emailTems -JsonName EmailTemplates
    ConvertTo-Json -Objects $filterScopes -JsonName FilterScopes
    ConvertTo-Json -Objects $actInfConfs -JsonName ActivityInformationConfigurations
    ConvertTo-Json -Objects $functions -JsonName Functions
    ConvertTo-Json -Objects $syncRules -JsonName SynchronizationRules
    ConvertTo-Json -Objects $syncFilters -JsonName SynchronizationFilter
}

Function Get-PortalConfigg {
    param(
        [Parameter(Mandatory=$False)]
        [Bool]
        $Source = $False
    )

    $homeConfs = Get-ObjectsFromConfigg -ObjectType HomepageConfiguration
    $portalUIConfs = Get-ObjectsFromConfigg -ObjectType PortalUIConfiguration
    $confs = Get-ObjectsFromConfigg -ObjectType Configuration
    $naviBarConfs = Get-ObjectsFromConfigg -ObjectType NavigationBarConfiguration
    $searchScopeConfs = Get-ObjectsFromConfigg -ObjectType SearchScopeConfiguration
    $objectVisualConfs = Get-ObjectsFromConfigg -ObjectType ObjectVisualizationConfiguration

    ConvertTo-Json -Objects $homeConfs -JsonName HomepageConfigurations
    ConvertTo-Json -Objects $portalUIConfs -JsonName PortalUIConfigurations
    ConvertTo-Json -Objects $confs -JsonName Configurations
    ConvertTo-Json -Objects $naviBarConfs -JsonName NavigationBarConfigurations
    ConvertTo-Json -Objects $searchScopeConfs -JsonName SearchScopeConfigurations
    ConvertTo-Json -Objects $objectVisualConfs -JsonName ObjectVisualizationConfigurations
}

Function Get-ObjectsFromConfigg {
    param(
        [Parameter(Mandatory=$True)]
        [String]
        $ObjectType
    )
    # This looks for objectTypes and expects objects with the type ObjectType
    $objects = Search-Resources -Xpath "/$ObjectType" -ExpectedObjectType $ObjectType
    return $objects
}