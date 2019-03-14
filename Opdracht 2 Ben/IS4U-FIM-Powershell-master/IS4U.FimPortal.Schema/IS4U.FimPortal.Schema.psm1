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

#Set-ResourceManagementClient -BaseAddress http://localhost:5725;
#endregion Lithnet

Function New-Person {
<#
	.SYNOPSIS
	Create a new person in the FIM Portal schema.

	.DESCRIPTION
	Create a new person in the FIM Portal schema.

	.EXAMPLE
	New-Person -Address "Prins Boudewijnlaan 41" -City Edegem -Country BE -Department "IBM/Imprivata" -DisplayName WDecruy 
	-Domain FIM -EmailAlias wdecruy -EmployeeId 696969 -EmployeeType Intern -FirstName Wouter -JobTitle "Security Architect" 
	-LastName Decruy -OfficePhone 0471151515 -PostalCode 2650 -RasAccessPermission "False"
#>
	param(
		[Parameter(Mandatory=$True)]
		[String]
		$Address,

		[Parameter(Mandatory=$True)]
		[String]
		$City,

		[Parameter(Mandatory=$True)]
		[String]
		[ValidateLength(2, 2)]    # Has to have a length of 2 (Example: BE)
		$Country,

		[Parameter(Mandatory=$True)]
		[String]
		$Department,

		[Parameter(Mandatory=$True)]
		[String]
		$DisplayName,

		[Parameter(Mandatory=$True)]
		[String]
		$Domain,

		[Parameter(Mandatory=$True)]
		[String]
		$EmailAlias,

		[Parameter(Mandatory=$True)]
		[Int]
		$EmployeeId,

		[Parameter(Mandatory=$True)]
		[String]
		$EmployeeType,

		[Parameter(Mandatory=$True)]
		[String]
		$FirstName,

		[Parameter(Mandatory=$True)]
		[String]
		$JobTitle,

		[Parameter(Mandatory=$True)]
		[String]
		$LastName,

		[Parameter(Mandatory=$True)]
		[Int]
		$OfficePhone,

		[Parameter(Mandatory=$True)]
		[Int]
		[ValidateRange(1000, 9999)]
		$PostalCode,

		[Parameter(Mandatory=$False)]
		[Bool]
		$RasAccessPermission = $False
	)

	$person = New-Resource -ObjectType Person	## In the real environment -ObjectType should be Person because User is the DisplayName
	$person.Address = $Address
	$person.City = $City
	$person.Country = $Country
	$person.Department = $Department
	$person.DisplayName = $DisplayName
	$person.Domain = $Domain
	$person.EmailAlias = $EmailAlias
	$person.EmployeeId = $EmployeeId
	$person.EmployeeType = $EmployeeType
	$person.FirstName = $FirstName
	$person.JobTitle = $JobTitle
	$person.LastName = $LastName
	$person.OfficePhone = $OfficePhone
	$person.PostalCode = $PostalCode
	$person.RasAccessPermission = $RasAccessPermission
	#Save-Resource $person
	return $person
}

Function Update-Person {
<#
	.SYNOPSIS
	Update a new person in the FIM Portal schema.

	.DESCRIPTION
	Update a new person in the FIM Portal schema.

	.EXAMPLE
	Update-Person -DisplayName WDecruy -FirstName Wouter -LastName Decruy
#>
	param(
		[Parameter(Mandatory=$False)]
		[String]
		$Address,

		[Parameter(Mandatory=$False)]
		[String]
		$City,

		[Parameter(Mandatory=$False)]
		[String]
		[ValidateLength(2, 2)]
		$Country,

		[Parameter(Mandatory=$False)]
		[String]
		$Department,

		[Parameter(Mandatory=$True)]
		[String]
		$DisplayName,

		[Parameter(Mandatory=$False)]
		[String]
		$Domain,

		[Parameter(Mandatory=$False)]
		[String]
		$EmailAlias,

		[Parameter(Mandatory=$False)]
		[Int]
		$EmployeeId,

		[Parameter(Mandatory=$False)]
		[String]
		$EmployeeType,

		[Parameter(Mandatory=$True)]
		[String]
		$FirstName,

		[Parameter(Mandatory=$False)]
		[String]
		$JobTitle,

		[Parameter(Mandatory=$True)]
		[String]
		$LastName,

		[Parameter(Mandatory=$False)]
		[Int]
		$OfficePhone,

		[Parameter(Mandatory=$False)]
		[Int]
		[ValidateRange(1000, 9999)]
		$PostalCode,

		[Parameter(Mandatory=$False)]
		[Bool]
		$RasAccessPermission = $False
	)
	
	<#
		PSBoundparameter is used so that only the parameters that get send will be used to update the User's atrributes!
		## In the real environment -ObjectType should be Person because User is the DisplayName
	#>
	$global:person = Get-Resource -ObjectType Person -AttributeName DisplayName -AttributeValue $DisplayName
	foreach ($boundparam in $PSBoundParameters.GetEnumerator()) {
		$global:person.($boundparam.Key) = $boundparam.Value
	}
	#Save-Resource $person
	return $person
}

Function Remove-Person {
<#
	.SYNOPSIS
	Remove a new person in the FIM Portal schema.

	.DESCRIPTION
	Remove a new person in the FIM Portal schema.

	.EXAMPLE
	Remove-Person -DisplayName WDecruy
#>
	param(
		[Parameter(Mandatory=$True)]
		[String]
		$DisplayName
	)
	##This is with pipeline and works in the real environment + -ObjectType must be changed into Person because User is the DisplayName
	#Get-Resource -ObjectType Person -AttributeName DisplayName -AttributeValue $DisplayName | Remove-Resource
	$id = Get-Resource -ObjectType Person -AttributeName DisplayName -AttributeValue $DisplayName -AttributesToGet ObjectID
	Remove-Resource -ID $id.ObjectID.Value
}

Function New-Attribute {
<#
	.SYNOPSIS
	Create a new attribute in the FIM Portal schema.

	.DESCRIPTION
	Create a new attribute in the FIM Portal schema.

	.EXAMPLE
	New-Attribute -Name Visa -DisplayName Visa -Type String -MultiValued "False"
#>
	param(
		[Parameter(Mandatory=$True)]
		[String]
		$Name,

		[Parameter(Mandatory=$True)]
		[String]
		$DisplayName,

		[Parameter(Mandatory=$False)]
		[String]
		$Description,

		[Parameter(Mandatory=$True)]
		[String]
		[ValidateScript({("String", "DateTime", "Integer", "Reference", "Boolean", "Text", "Binary") -ccontains $_})]
		$Type,

		[Parameter(Mandatory=$False)]
		[String]
		$MultiValued = "False"
	)
	$obj = New-Resource -ObjectType AttributeTypeDescription
	$obj.DisplayName = $DisplayName
	$obj.Name = $Name
	$obj.Description = $Description
	$obj.DataType = $Type
	$obj.MultiValued = $MultiValued
	#Save-Resource $obj				## Is for real environment
	#$id = Get-Resource -ObjectType AttributeTypeDescription -AttributeName Name -AttributeValue $Name -AttributesToGet ObjectID
	#return $id.ObjectID.Value		## For testing, .ObjectID.Value is for real environment
	return $obj		## For testing purposes
}

Function Update-Attribute {
<#
	.SYNOPSIS
	Update an attribute in the FIM Portal schema.

	.DESCRIPTION
	Update an attribute in the FIM Portal schema.

	.EXAMPLE
	Update-Attribute -Name Visa -DisplayName Visa -Description "Visa card number"
#>
	param(
		[Parameter(Mandatory=$True)]
		[String]
		$Name,

		[Parameter(Mandatory=$True)]
		[String]
		$DisplayName,

		[Parameter(Mandatory=$False)]
		[String]
		$Description
	)
	$obj = Get-Resource -ObjectType AttributeTypeDescription -AttributeName Name -AttributeValue $Name
	$obj.DisplayName = $DisplayName
	$obj.Description = $Description
	#Save-Resource $obj
	return $obj#.ObjectID.Value		## For testing, .ObjectID.Value is for real environment
}

Function Remove-Attribute {
<#
	.SYNOPSIS
	Remove an attribute from the FIM Portal schema.

	.DESCRIPTION
	Remove an attribute from the FIM Portal schema.

	.EXAMPLE
	Remove-Attribute -Name Visa
#>
	param(
		[Parameter(Mandatory=$True)]
		[String]
		$Name
	)
	#This is with pipeline and works in real environment!
	#Get-Resource -ObjectType AttributeTypeDescription -AttributeName Name -AttributeValue $Name | Remove-Resource
	# To be sure we get the correct object the ID gets returned from Get-Resource, this ID will be send with Remove-Resource
	$id = Get-Resource -ObjectType AttributeTypeDescription -AttributeName Name -AttributeValue $Name -AttributesToGet ID
	Remove-Resource -ID $id.ObjectID.Value
}

Function New-Binding {
<#
	.SYNOPSIS
	Create a new attribute binding in the FIM Portal schema.

	.DESCRIPTION
	Create a new attribute binding in the FIM Portal schema.

	.EXAMPLE
	New-Binding -AttributeName Visa -DisplayName "Visa Card Number"

	.EXAMPLE
	New-Binding -AttributeName Visa -DisplayName "Visa Card Number" -Required $False -ObjectType Person
#>
	param(
		[Parameter(Mandatory=$True)]
		[String]
		$AttributeName,

		[Parameter(Mandatory=$True)]
		[String]
		$DisplayName,

		[Parameter(Mandatory=$False)]
		[String]
		$Description,

		[Parameter(Mandatory=$False)]
		[String]
		$Required = "False",

		[Parameter(Mandatory=$False)]
		[String]
		$ObjectType = "Person"
	)
	$attrId = Get-Resource -ObjectType AttributeTypeDescription -AttributeName Name -AttributeValue $AttributeName #-AttributesToGet ObjectID
	$objId = Get-Resource -ObjectType ObjectTypeDescription -AttributeName Name -AttributeValue $ObjectType #-AttributesToGet ObjectID
	$obj = New-Resource -ObjectType BindingDescription
	$obj.Required = $Required
	$obj.DisplayName = $DisplayName
	$obj.Description = $Description
	$obj.BoundAttributeType = $attrId#.ObjectID.Value		## For id testing in real environment
	$obj.BoundObjectType = $objId#.ObjectID.Value			## For id testing in real environment
	#Save-Resource $obj
	#$Id = Get-Resource -ObjectType BindingDescription -AttributeName DisplayName -AttributeValue $DisplayName -AttributesToGet ObjectID
	#return $obj.ObjectID.Value		## For testing, to get the id of the resource ask for .ObjectID.Value (in real environment)
	## For Tests
	$obj.id = Get-Resource -ObjectType BindingDescription -AttributeName DisplayName -AttributeValue $DisplayName
	return $obj
}

Function Update-Binding {
<#
	.SYNOPSIS
	Update an attribute binding in the FIM Portal schema.

	.DESCRIPTION
	Update an attribute binding in the FIM Portal schema.

	.EXAMPLE
	Update-Binding -AttributeName Visa -DisplayName "Visa Card Number"

	.EXAMPLE
	Update-Binding -AttributeName Visa -DisplayName "Visa Card Number" -Required $False -ObjectType Person
#>
	param(
		[Parameter(Mandatory=$True)]
		[String]
		$AttributeName,

		[Parameter(Mandatory=$True)]
		[String]
		$DisplayName,

		[Parameter(Mandatory=$False)]
		[String]
		$Description,

		[Parameter(Mandatory=$False)]
		[String]
		$Required = "False",

		[Parameter(Mandatory=$False)]
		[String]
		$ObjectType = "Person"
	)
	$attrId = Get-Resource -ObjectType AttributeTypeDescription -AttributeName Name -AttributeValue $AttributeName -AttributesToGet ObjectID
	$objId = Get-Resource -ObjectType ObjectTypeDescription -AttributeName Name -AttributeValue $ObjectType -AttributesToGet ObjectID
	$id = Get-Resource -ObjectType BindingDescription -AttributeValuePairs `
	@{BoundAttributeType=$attrId.ObjectID.Value; BoundObjectType=$objId.ObjectID.Value} -AttributesToGet ObjectID
	#[UniqueIdentifier] $id = Get-Resource -ObjectType BindingDescription -AttributeValuePairs @{BoundAttributeType=$attrId; BoundObjectType=$objId} -AttributesToGet ID
	$obj = Get-Resource -ID = $id.ObjectID.Value
	$obj.Required = $Required
	$obj.DisplayName = $DisplayName
	$obj.Description = $Description
	#Save-Resource $obj
	return $id.ObjectID.Value		## For testing
}

Function Remove-Binding {
<#
	.SYNOPSIS
	Remove an attribute binding from the FIM Portal schema.

	.DESCRIPTION
	Remove an attribute binding from the FIM Portal schema.

	.EXAMPLE
	Remove-Binding -AttributeName Visa
#>
	param(
		[Parameter(Mandatory=$True)]
		[String]
		$AttributeName,

		[Parameter(Mandatory=$False)]
		[String]
		$ObjectType = "Person"
	)
	<#$attrId = Get-FimObjectID -ObjectType AttributeTypeDescription -AttributeName Name -AttributeValue $AttributeName
	$objId = Get-FimObjectID -ObjectType ObjectTypeDescription -AttributeName Name -AttributeValue $ObjectType
	$binding = Get-FimObject -Filter "/BindingDescription[BoundAttributeType='$attrId' and BoundObjectType='$objId']"
	#[UniqueIdentifier] $id = $binding.ObjectID
    $id = $binding
	#Remove-FimObject -AnchorName ObjectID -AnchorValue $id.Value -ObjectType BindingDescription
	Remove-FimObject -AnchorName ObjectID -AnchorValue $id[0] -ObjectType BindingDescription#>
	$attrId = Get-Resource -ObjectType AttributeTypeDescription -AttributeName Name -AttributeValue $AttributeName -AttributesToGet ObjectID
	$objId = Get-Resource -ObjectType ObjectTypeDescription -AttributeName Name -AttributeValue $ObjectType -AttributesToGet ObjectID
	$id = Get-Resource -ObjectType BindingDescription -AttributeValuePairs @{BoundAttributeType=$attrId.ObjectID.Value; BoundObjectType=$objId.ObjectID.Value} -AttributesToGet ObjectID
	Remove-Resource -ID $id.ObjectID.Value		## For testing
}

<# Niet gebruikt voorlopig #>
Function New-AttributeAndBinding {
<#
	.SYNOPSIS
	Create a new attribute, attribute binding, MPR-config, filter permission, ... in the FIM Portal schema.

	.DESCRIPTION
	Create a new attribute, attribute binding, MPR-config, filter permission, ... in the FIM Portal schema.

	.EXAMPLE
	New-AttributeAndBinding -AttrName Visa -DisplayName "Visa Card Number" -Type String
#>
	param(
		[Parameter(Mandatory=$True)]
		[String]
		$Name,

		[Parameter(Mandatory=$True)]
		[String]
		$DisplayName,

		[Parameter(Mandatory=$True)]
		[String]
		[ValidateScript({("String", "DateTime", "Integer", "Reference", "Boolean", "Text", "Binary") -contains $_})]
		$Type,

		[Parameter(Mandatory=$False)]
		[String]
		$MultiValued = "False",

		[Parameter(Mandatory=$False)]
		[String]
		$ObjectType = "Person"
	)

	[UniqueIdentifier] $attrId = New-Attribute -Name $Name -DisplayName $DisplayName -Type $Type -MultiValued $MultiValued
	New-Binding -AttributeName $Name -DisplayName $DisplayName -ObjectType $ObjectType
	if($ObjectType -eq "Person") {
		Add-AttributeToMPR -AttrName $Name -MprName "Administration: Administrators can read and update Users"
		Add-AttributeToMPR -AttrName $Name -MprName "Synchronization: Synchronization account controls users it synchronizes"
	} elseif($ObjectType -eq "Group") {
		Add-AttributeToMPR -AttrName $Name -MprName "Group management: Group administrators can update group resources"
		Add-AttributeToMPR -AttrName $Name -MprName "Synchronization: Synchronization account controls group resources it synchronizes"
	}
	Add-AttributeToFilterScope -AttributeId $attrId -DisplayName "Administrator Filter Permission"
}

<# Niet gebruikt voorlopig #>
Function Remove-AttributeAndBinding {
<#
	.SYNOPSIS
	Remove an attribute, attribute binding, MPR-config, filter permission, ... from the FIM Portal schema.

	.DESCRIPTION
	Remove an attribute, attribute binding, MPR-config, filter permission, ... from the FIM Portal schema.

	.EXAMPLE
	Remove-AttributeAndBinding -AttrName Visa
#>
	param(
		[Parameter(Mandatory=$True)]
		[String]
		$Name,

		[Parameter(Mandatory=$False)]
		[String]
		$ObjectType = "Person"
	)
	if($ObjectType -eq "Person") {
		Remove-AttributeFromMPR -AttrName $Name -MprName "Administration: Administrators can read and update Users"
		Remove-AttributeFromMPR -AttrName $Name -MprName "Synchronization: Synchronization account controls users it synchronizes"
	}
	Remove-AttributeFromFilterScope -AttributeName $Name -DisplayName "Administrator Filter Permission"
	Remove-Binding -AttributeName $Name -ObjectType $ObjectType
	Remove-Attribute -Name $Name
}

<# Niet gebruikt voorlopig #>
Function Import-SchemaAttributesAndBindings {
<#
	.SYNOPSIS
	Create new attributes and bindings based on data in given CSV file.

	.DESCRIPTION
	Create new attributes and bindings based on data in given CSV file.

	.EXAMPLE
	Import-SchemaAttributesAndBindings -CsvFile ".\SchemaAttributesAndBindings.csv"
#>
	param(
		[Parameter(Mandatory=$True)]
		[String]
		$CsvFile

		### TODO : add parameter for MPR
	)
	$csv = Import-Csv $CsvFile
	ForEach ($entry in $csv) {
		New-AttributeAndBinding -Name $entry.SystemName -DisplayName $entry.DisplayName -Type $entry.DataType -MultiValued $entry.MultiValued -ObjectType $entry.ObjectType
	}
}

Function Import-SchemaBindings {
<#
	.SYNOPSIS
	Create new bindings based on data in given CSV file.
	
	.DESCRIPTION
	Create new bindings based on data in given CSV file.
	All referenced attributes are assumed to exist already in the schema.

	.EXAMPLE
	Import-SchemaBindings -CsvFile ".\SchemaBindings.csv"
#>
	param(
		[Parameter(Mandatory=$True)]
		[String]
		$CsvFile
	)
	$csv = Import-Csv $CsvFile
	ForEach ($entry in $csv) {
		New-Binding -AttributeName $entry.SystemName -DisplayName $entry.DisplayName -ObjectType $entry.ObjectType
	}
}

Function New-ObjectType {
<#
	.SYNOPSIS
	Create a new object type in the FIM Portal schema.

	.DESCRIPTION
	Create a new object type in the FIM Portal schema.

	.EXAMPLE
	New-ObjectType -Name Department -DisplayName Department -Description Department
#>
	param(
		[Parameter(Mandatory=$True)]
		[String]
		$Name,

		[Parameter(Mandatory=$True)]
		[String]
		$DisplayName,

		[Parameter(Mandatory=$True)]
		[String]
		$Description
	)
	<#$changes = @{}
	$changes.Add("DisplayName", $DisplayName)
	$changes.Add("Name", $Name)
	$changes.Add("Description", $Description)
	New-FimImportObject -ObjectType ObjectTypeDescription -State Create -Changes $changes -ApplyNow
	[GUID] $id = Get-FimObjectID -ObjectType ObjectTypeDescription -AttributeName Name -AttributeValue $Name
	return $id#>
	$obj = New-Resource -ObjectType ObjectTypeDescription
	$obj.DisplayName = $DisplayName
	$obj.Name = $Name
	$obj.Description = $Description
	#Save-Resource $obj
	$id = Get-Resource -ObjectType ObjectTypeDescription -AttributeName Name -AttributeValue $Name -AttributesToGet ObjectID	# used to be -AttributesToGet ID
	return $id.ObjectID.Value
}

Function Update-ObjectType {
<#
	.SYNOPSIS
	Update the object type in the FIM Portal schema.

	.DESCRIPTION
	Update the object type in the FIM Portal schema.

	.EXAMPLE
	Update-ObjectType -Name Department -DisplayName Department -Description Department
#>
	param(
		[Parameter(Mandatory=$True)]
		[String]
		$Name,

		[Parameter(Mandatory=$True)]
		[String]
		$DisplayName,

		[Parameter(Mandatory=$True)]
		[String]
		$Description
	)
	$obj = Get-Resource -ObjectType ObjectTypeDescription -AttributeName Name -AttributeValue $Name
	$obj.DisplayName = $DisplayName
	$obj.Description = $Description
	#Save-Resource $obj
	#$id = Get-Resource -ObjectType ObjectTypeDescription -AttributeName Name -AttributeValue $Name -AttributesToGet ID	# Dit wordt vervangen
	#return $id	# Dit wordt vervangen
	return $obj.ObjectID.Value
}

Function Remove-ObjectType {		## No rights to remove an ObjectType, only admins can do this!
<#
	.SYNOPSIS
	Remove an object type from the FIM Portal schema.

	.DESCRIPTION
	Remove an object type from the FIM Portal schema.

	.EXAMPLE
	Remove-ObjectType -Name Department
#>
	param(
		[Parameter(Mandatory=$True)]
		[String]
		$Name
	)
	#Remove-FimObject -AnchorName Name -AnchorValue $Name -ObjectType ObjectTypeDescription
	#This is with pipeline and works in real environment
	#Get-Resource -ObjectType ObjectTypeDescription -AttributeName Name -AttributeValue $Name | Remove-Resource
	$id = Get-Resource -ObjectType ObjectTypeDescription -AttributeName Name -AttributeValue $Name -AttributesToGet ObjectID #-AttributesToGet ID
	Remove-Resource -ID $id.ObjectID.Value
}

Function New-ObjectTypeConfiguration {
<#
	.SYNOPSIS
	Create a new object type configuration.

	.DESCRIPTION
	Create a new object type based on the given config file.
	This includes creating a new object type, a MPR, default attributes and bindings,
	search scope, a navigation bar resource and configuring a synchronization fiter.

	.EXAMPLE
	New-ObjectTypeConfiguration -ConfigFile .\newObject.xml
#>
	param(
		[Parameter(Mandatory=$True)]
		[String]
		$ConfigFile
	)
	Add-TypeAccelerators -Assembly System.Xml.Linq -Class XAttribute
	$config = [XDocument]::Load((Join-Path $pwd $ConfigFile))
	$root = [XElement] $config.Root
	$objectConfig = [XElement] $root.Element("Object")

	#-------------------------------
	Write-Host "Create object type"
	#-------------------------------
	[UniqueIdentifier] $objectTypeId = [Guid]::Empty
	$objectName = $objectConfig.Attribute("SystemName").Value
	$objectDisplayName = $objectConfig.Attribute("DisplayName").Value
	$objectDescription = $objectConfig.Element("Description").Value
	$objectExists = Test-ObjectExists -Value $objectName -Attribute Name -ObjectType ObjectTypeDescription
	if($objectExists) {
		Write-Host "Update existing object type '$objectName'"
		$objectTypeId = Update-ObjectType -Name $objectName -DisplayName $objectDisplayName -Description $objectDescription
	} else {
		Write-Host "Create object type '$objectName'"
		$objectTypeId = New-ObjectType -Name $objectName -DisplayName $objectDisplayName -Description $objectDescription
	}

	#-------------------------------
	Write-Host "Add object to synchronization filter"
	#-------------------------------
	Add-ObjectToSynchronizationFilter -ObjectId $objectTypeId

	#-------------------------------
	Write-Host "Create Set"
	#-------------------------------
	[UniqueIdentifier] $setId = [Guid]::Empty
	$setConfig = [XElement] $objectConfig.Element("Set")
	$setDisplayName = $setConfig.Attribute("DisplayName").Value
	$setExists = Test-ObjectExists -Value $setDisplayName -Attribute DisplayName -ObjectType Set
	if($setExists) {
		Write-Host "Update existing set '$setDisplayName'"
		$setId = Update-Set -DisplayName $setDisplayName -Condition "/$objectName" -Description $setConfig.Attribute("Description").Value
	} else {
		Write-Host "Create set '$setDisplayName'"
		$setId = New-Set -DisplayName $setDisplayName -Condition "/$objectName" -Description $setConfig.Attribute("Description").Value
	}

	#-------------------------------
	Write-Host "Configure management policy rules"
	#-------------------------------
	$policy = $objectConfig.Element("Policy")
	foreach($mprConfig in $policy.Elements("MPR")) {
		$mprDisplayName = $mprConfig.Element("DisplayName").Value
		[UniqueIdentifier] $mprRequestors = Get-FimObjectID -ObjectType Set -AttributeName DisplayName -AttributeValue $mprConfig.Element("Requestors").Value
		$mprDescription = $mprConfig.Element("Description").Value
		$mprType = $mprConfig.Attribute("Type").Value
		$mprGrant = $mprConfig.Attribute("GrantRight").Value
		$mprDisabled = $mprConfig.Attribute("Disabled").Value
		$mprActions = @()
		foreach($operation in $mprConfig.Element("Operations").Elements("Operation")) {
			$mprActions += $operation.Value
		}
		$mprAttr = @()
		foreach($attribute in $mprConfig.Element("Attributes").Elements("Attribute")) {
			$mprAttr += $attribute.Value
		}
		$mprExists = Test-ObjectExists -Value $mprDisplayName -Attribute DisplayName -ObjectType ManagementPolicyRule
		if($mprExists) {
			Write-Host "Update existing mpr '$mprDisplayName'"
			Update-Mpr -DisplayName $mprDisplayName -PrincipalSetId $mprRequestors -SetId $setId -ActionType $mprActions -ActionParameter $mprAttr -GrantRight $mprGrant -Description $mprDescription -Disabled $mprDisabled
		} else {
			Write-Host "Create mpr '$mprDisplayName'"
			New-Mpr -DisplayName $mprDisplayName -PrincipalSetId $mprRequestors -SetId $setId -ActionType $mprActions -ActionParameter $mprAttr -GrantRight $mprGrant -ManagementPolicyRuleType $mprType -Description $mprDescription -Disabled $mprDisabled
		}
	}
	
	$attrConfig = $objectConfig.Element("Attribute")
	if($attrConfig) {
		#-------------------------------
		Write-Host "Create the reference attribute"
		#-------------------------------
		[UniqueIdentifier] $attrId = [Guid]::Empty
		$attrName = $attrConfig.Attribute("SystemName").Value
		$attrDisplayName = $attrConfig.Attribute("DisplayName").Value
		$attrDescription = $attrConfig.Attribute("Description").Value
		$attrMultivalued = $attrConfig.Element("Multivalued").Value
		$attrExists = Test-ObjectExists -Value $attrName -Attribute Name -ObjectType AttributeTypeDescription
		if($attrExists) {
			Write-Host "Update existing attribute '$attrName'"
			$attrId = Update-Attribute -Name $attrName -DisplayName $attrDisplayName -Description $attrDescription
		} else {
			Write-Host "Create attribute '$attrName'"
			$attrId = New-Attribute -Name $attrName -DisplayName $attrDisplayName -Description $attrDescription -Type "Reference" -MultiValued $attrMultivalued
		}

		#-------------------------------
		Write-Host "Add reference attribute to MPR's"
		#-------------------------------
		foreach($mprConfig in $attrConfig.Element("Policy").Elements("MPR")) {
			Add-AttributeToMPR -AttrName $attrName -MprName $mprConfig.Element("DisplayName").Value
		}

		#-------------------------------
		Write-Host "Create bindings for the reference attribute"
		#-------------------------------
		foreach($bindingConfig in $attrConfig.Element("Bindings").Elements("Binding")) {
			$bindingDisplayName = $bindingConfig.Attribute("DisplayName").Value
			$bindingRequired = $bindingConfig.Attribute("Required").Value
			$boundObjectType = $bindingConfig.Attribute("Object").Value
			$bindingExists = Test-ObjectExists -Value $bindingDisplayName -Attribute DisplayName -ObjectType BindingDescription
			if($bindingExists) {
				Write-Host "Update existing binding '$bindingDisplayName'"
				Update-Binding -AttributeName $attrName -DisplayName $bindingDisplayName -Required $bindingRequired -ObjectType $boundObjectType
			} else {
				Write-Host "Create binding '$bindingDisplayName'"
				New-Binding -AttributeName $attrName -DisplayName $bindingDisplayName -Required $bindingRequired -ObjectType $boundObjectType
			}
		}
		
		#-------------------------------
		$rcdcName = $attrConfig.Element("RCDCs").Element("RCDC").Attribute("DisplayName").Value
		Write-Host "Edit RCDC $rcdcName"
		#-------------------------------
		$rcdcObjectType = $attrConfig.Element("RCDCs").Element("RCDC").Element("Object").Value
		$rcdcGrouping = $attrConfig.Element("RCDCs").Element("RCDC").Element("Grouping").Value
		$rcdcCaption = $attrConfig.Element("RCDCs").Element("RCDC").Element("Caption").Value
		$rcdcElement = Get-RcdcIdentityPicker -AttributeName $attrName -ObjectType $rcdcObjectType
		Add-ElementToRcdc -DisplayName $rcdcName -GroupingName $rcdcGrouping -RcdcElement $rcdcElement -Caption $rcdcCaption
	}

	#-------------------------------
	Write-Host "Create search scope"
	#-------------------------------
	$searchScopeConfig = $objectConfig.Element("SearchScope")
	$searchScopeDisplayName = $searchScopeConfig.Attribute("DisplayName").Value
	$searchScopeOrder = $searchScopeConfig.Attribute("Order").Value
	$searchScopeContext = $searchScopeConfig.Element("Context").Value
	$searchScopeColumn = $searchScopeConfig.Element("Column").Value
	$searchScopeKeywords = @()
	foreach($keyword in $searchScopeConfig.Element("UsageKeywords").Elements("UsageKeyword")) {
		$searchScopeKeywords += $keyword.Value
	}
	$searchScopeExists = Test-ObjectExists -Value $searchScopeDisplayName -Attribute DisplayName -ObjectType SearchScopeConfiguration
	if($searchScopeExists) {
		Write-Host "Update existing search scope '$searchScopeDisplayName'"
		Update-SearchScope -DisplayName $searchScopeDisplayName -Order $searchScopeOrder -ObjectType $objectName -Context $searchScopeContext -Column $searchScopeColumn -UsageKeyWords $searchScopeKeywords
	} else {
		Write-Host "Create search scope '$searchScopeDisplayName'"
		New-SearchScope -DisplayName $searchScopeDisplayName -Order $searchScopeOrder -ObjectType $objectName -Context $searchScopeContext -Column $searchScopeColumn -UsageKeyWords $searchScopeKeywords
	}

	#-------------------------------
	Write-Host "Create navigation bar"
	#-------------------------------
	$navBar = $objectConfig.Element("NavigationBarResource")
	$navBarDisplayName = $navBar.Attribute("DisplayName").Value
	$navBarOrder = $navBar.Attribute("Order").Value
	$navBarParentOrder = $navBar.Attribute("ParentOrder").Value
	$navBarKeywords = @()
	foreach($keyword in $navBar.Element("UsageKeywords").Elements("UsageKeyword")) {
		$navBarKeywords += $keyword.Value
	}
	$navBarExists = Test-ObjectExists -Value $navBarDisplayName -Attribute DisplayName -ObjectType NavigationBarConfiguration
	if($navBarExists) {
		Write-Host "Update existing navigation bar '$navBarDisplayName'"
		Update-NavigationBar -DisplayName $navBarDisplayName -Order $navBarOrder -ParentOrder $navBarParentOrder -ObjectType $objectName -UsageKeyWords $navBarKeywords
	} else {
		Write-Host "Create navigation bar '$navBarDisplayName'"
		New-NavigationBar -DisplayName $navBarDisplayName -Order $navBarOrder -ParentOrder $navBarParentOrder -ObjectType $objectName -UsageKeyWords $navBarKeywords
	}

	#-------------------------------
	Write-Host "Create RCDC configurations for $objectName"
	#-------------------------------
	$rcdcCreate = Get-DefaultRcdc -Caption "Create $objectName" -Xml "defaultCreateRcdc.xml"
	New-Rcdc -DisplayName "Configuration for $objectName Creation" -TargetObjectType $objectName -ConfigurationData $rcdcCreate.ToString() -AppliesToCreate
	$rcdcEdit = Get-DefaultRcdc -Caption "Edit $objectName" -Xml "defaultEditRcdc.xml"
	New-Rcdc -DisplayName "Configuration for $objectName Editing" -TargetObjectType $objectName -ConfigurationData $rcdcEdit.ToString() -AppliesToEdit
	$rcdcView = Get-DefaultRcdc -Caption "View $objectName" -Xml "defaultViewRcdc.xml"
	New-Rcdc -DisplayName "Configuration for $objectName Viewing" -TargetObjectType $objectName -ConfigurationData $rcdcView.ToString() -AppliesToView
}
