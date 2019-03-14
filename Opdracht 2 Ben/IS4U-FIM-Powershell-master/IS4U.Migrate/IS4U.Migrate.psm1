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

Function Import-DeltaFile {
    $Attributes = Search-Resources -Xpath "/AttributeTypeDescription" -ExpectedObjectType AttributeTypeDescription
    $Bindings = Search-Resources -Xpath "/BindingDescription" -ExpectedObjectType BindingDescription
    $Objects = Search-Resources -Xpath "/ObjectTypeDescription" -ExpectedObjectType ObjectTypeDescription
}

Function Get-SchemaConfig {
    $FileName = "newObject.xml"
    $File = [System.Xml.XmlDocument] (Get-Content $FileName)
}

Function Get-PortalConfig {

}

Function Get-PolicyConfig {
    
}

Function New-DeltaFile {

}