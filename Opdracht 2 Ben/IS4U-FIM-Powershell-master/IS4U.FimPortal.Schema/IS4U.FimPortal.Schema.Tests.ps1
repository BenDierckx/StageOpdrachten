Import-Module IS4U.FimPortal.Schema

Class NewFimImportObject {
    [string]$ObjectType
    [string]$State
    [Hashtable]$Changes = @{}
    [bool]$ApplyNow
    [bool]$SkipDuplicateCheck
    [bool]$PassThru
    [Int]$TargetObjectIdentifier
}

Describe "New-Attribute" {
    
    Context "Module Setup" {
        It "module file exists" {
            Get-Module -ListAvailable | Where {$_.Name -eq 'IS4U.FimPortal.Schema'}
        }
    }

    Context "With parameters (mandatory)" {
        $fimImport = [NewFimImportObject]::new()
        Mock New-FimImportObject { $fimImport } -ModuleName "IS4U.FimPortal.Schema" -MockWith {$ObjectType, $State, $changes}
        $result = New-Attribute -Name Visa -DisplayName Visa -Type String -MultiValued "False"

        It "New-FimImportObject get called" {
            Assert-MockCalled -CommandName New-FimImportObject -ModuleName "IS4U.FimPortal.Schema"
        }
        
        It "Parameters get saved into object (Name, DisplayName, Type (mandatory), Description, MultiValued (Optional)" {
            Write-Host($result.changes)
            Assert-MockCalled New-FimImportObject -ParameterFilter{
                $changes["Name"] -eq "Visa" -and $changes["DisplayName"] -eq "Visa" -and $changes["DataType"] -eq "String"
            } -ModuleName "IS4U.FimPortal.Schema"
        }

        It "Return correct object" {
            Write-Host($result[2].Values)
            $result[0] -eq "AttributeTypeDescription" -and $result[1] -eq "Create" -and $result[2]["Name"] -eq "Visa" | Should be $true
        }
    }
}

Describe "Update-Attribute" {
    Context "With parameters (mandatory)" {
        $fimImport = [NewFimImportObject]::new()
        Mock New-FimImportObject { $fimImport } -ModuleName "IS4U.FimPortal.Schema" -MockWith {
            $ObjectType, $State, $anchor, $changes, $ApplyNow
        }
        #[GUID]$Id = "66b7d725-8226-4ccd-99ad-3540c44c49b6"
        Mock Get-FimObjectID { New-Guid } -ModuleName "IS4U.FimPortal.Schema"
        $result = Update-Attribute -Name Visum -DisplayName Visum -Description "Update test"
        It "Module file is ready to be loaded" {
            Get-Module -ListAvailable | Where {$_.Name -eq 'IS4U.FimPortal.Schema'}
        }

        It "Parameters get saved into object (Name, DisplayName, Description)" {
            Assert-MockCalled New-FimImportObject -ParameterFilter {
                # To-Do anchor in place of $result[2]
                $ObjectType -eq "AttributeTypeDescription" -and $State -eq "Put" -and $changes["DisplayName"] -eq "Visum" -and $result[2].Values -eq "Visum"
            } -ModuleName "IS4U.FimPortal.Schema"
        }

        It "Variable id gets filled and Update-Attribute returns a Guid" {
            $result | Should Not BeNullOrEmpty
            $result[5].GetType() -eq [GUID]
        }
    }
}

Describe "Remove-Attribute" {
    Context "With parameter Name" {
        Mock Remove-FimObject -ModuleName "IS4U.FimPortal.Schema" -MockWith {
            $AnchorName, $AnchorValue, $ObjectType
        }
        Remove-Attribute -Name "Visa"

        It "Correct parameters go to Remove-FimObject" {
            Assert-MockCalled Remove-FimObject -ParameterFilter {
                $AnchorName -eq "Name" -and $AnchorValue -eq "Visa" -and $ObjectType -eq "AttributeTypeDescription"
            } -ModuleName "IS4U.FimPortal.Schema"
        }
    }
}

Describe "New-Binding" {   
    Context "New-Binding with parameters, testing GUID (without parameters to New-FimObject)" {
        $fimImport = [NewFimImportObject]::new()
        Mock New-FimImportObject { $fimImport } -ModuleName "IS4U.FimPortal.Schema" -MockWith {
            $ObjectType, $State, $changes, $ApplyNow, $SkipDuplicateCheck, $PassThru
        }
        Mock Get-FimObjectID { New-Guid } -ModuleName "IS4U.FimPortal.Schema"
        $result = New-Binding -AttributeName Visa -DisplayName "Visa Card Number" -Required $False -ObjectType Person
        It "AttrId and ObjId gets Id from Get-FimObjectID" {
            $result[2]["BoundObjectType"].GetType() -eq [GUID] | Should be $true
        }
    }

    Context "New-Binding with parameters aswell to mock to Get-FimObjectId" {
        $fimImport = [NewFimImportObject]::new()
        Mock New-FimImportObject { $fimImport } -ModuleName "IS4U.FimPortal.Schema" -MockWith {
            $ObjectType, $State, $changes, $ApplyNow, $SkipDuplicateCheck, $PassThru
        }

        Mock Get-FimObjectID { New-Guid } -ModuleName "IS4U.FimPortal.Schema" -MockWith {
            $ObjectType, $AttributeName, $AttributeValue
        }

        $result = New-Binding -AttributeName Visa -DisplayName "Visa Card Number" -Required $False -ObjectType Person
        
        It "AttrId sends correct parameters (+ test hashtable changes gets filled)" {
            #return[2]["BoundAttributeType"][0]
            # ^Changes          ^=           ^ObjectType
            $result[2]["BoundAttributeType"][0] -eq "AttributeTypeDescription" | Should be $true
            Write-Host($result[2])
        }

        It "ObjId sends correct parameters (+ test hashtable changes gets filled)" {
            $result[2]["BoundObjectType"][0] -eq "ObjectTypeDescription" | Should be $true
        }

        It "New-Binding returns correct object" {
            Write-Host($result[2].Values)
            $result[0] -eq "BindingDescription" -and $result[1] -eq "Create" -and $result[2]["DisplayName"] -eq "Visa card number" | Should be $true
        }
    }
}

Describe "Update-Binding" {
    $fimImport = [NewFimImportObject]::new()
    Mock New-FimImportObject { $fimImport } -ModuleName "IS4U.FimPortal.Schema" -MockWith {
        $ObjectType, $State, $anchor, $changes, $ApplyNow
    }
    Mock Get-FimObject -ModuleName "IS4U.FimPortal.Schema" -MockWith {
        $Filter, $attrId, $objId
    }
    Context "Update-Binding with parameters: testing id's that get returned from mock New-FimObject" {
        Mock Get-FimObjectID { return "34b7bfae-e636-41d2-8750-acb0a1ea7a35" } -ModuleName "IS4U.FimPortal.Schema"
        $result = Update-Binding -AttributeName Visa -DisplayName "Visa Card Number" -Required $False -ObjectType Person
        It "AttrId and ObjId gets Id from filter" {
            #result[5] = anchor
            $result[5] | Should be "/BindingDescription[BoundAttributeType='34b7bfae-e636-41d2-8750-acb0a1ea7a35' and BoundObjectType='34b7bfae-e636-41d2-8750-acb0a1ea7a35']"
        }
    }

    Context "Update-Binding with parameters: testing variables get filled and returns" {
        Mock Get-FimObjectID { New-Guid } -ModuleName "IS4U.FimPortal.Schema" -MockWith {
            $ObjectType, $AttributeName, $AttributeValue
        }

        $result = Update-Binding -AttributeName Visa -DisplayName "Visa Card Number" -Required $False -ObjectType Person

        It "AttrId sends correct parameters (+ test hashtable changes gets filled)" {
            Assert-MockCalled Get-FimObjectID -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
                $ObjectType -eq "AttributeTypeDescription" -and $AttributeName -eq "Name" -and $AttributeValue -eq "Visa"
            } -Exactly 1
        }

        It "ObjId sends correct parameters (+ test hashtable changes gets filled)" {
            Assert-MockCalled Get-FimObjectID -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
                $ObjectType -eq "ObjectTypeDescription" -and $AttributeName -eq "Name" -and $AttributeValue -eq "Person"
            } -Exactly 1
        }

        It "Parameters get saved into object (ObjectID, DisplayName, Description)" {
            Assert-MockCalled New-FimImportObject -ParameterFilter {
                # To-Do anchor in place of $result[2]
                #$ObjectType -eq "BindingDescription" -and $State -eq "Put" -and $changes["DisplayName"] -eq "Visa card number" -and $result[2].Values -eq "Visum"
                $ObjectType | Should be "BindingDescription"
                $State | Should be "Put"
                #$anchor?
                $changes["DisplayName"] | Should be "Visa Card Number"
                $changes["Description"] | Should BeNullOrEmpty

            } -ModuleName "IS4U.FimPortal.Schema"
        }
    }
}

Describe "Remove-Binding" {
    Mock Get-FimObject -ModuleName "IS4U.FimPortal.Schema" -MockWith {
        $Filter, $attrId, $objId
    }
    Mock Remove-FimObject -ModuleName "IS4U.FimPortal.Schema" -MockWith {
        $AnchorName, $AnchorValue, $ObjectType
    }

    Context "Remove-Binding with parameters: testing id's that get returned from mock New-FimObjectId" {
        Mock Get-FimObjectID { return "34b7bfae-e636-41d2-8750-acb0a1ea7a35" } -ModuleName "IS4U.FimPortal.Schema"
        $result = Remove-Binding -AttributeName "Visa"
        It "attrId and ObjId get id from Get-FimObjectId and binding get correct parameters filled" {
            $result[1] | Should be "/BindingDescription[BoundAttributeType='34b7bfae-e636-41d2-8750-acb0a1ea7a35' and BoundObjectType='34b7bfae-e636-41d2-8750-acb0a1ea7a35']"
        }
    }

    Context "Remove-Binding with parameters: testing correct variables get filled and send" {
        Mock Get-FimObjectID { return New-Guid } -ModuleName "IS4U.FimPortal.Schema" -MockWith {
            $ObjectType, $AttributeName, $AttributeValue
        }
        Remove-Binding -AttributeName "Visa"

        It "Get-FimObjectId get correct parameters for variables attrId" {
            Assert-MockCalled Get-FimObjectID -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
                $ObjectType -eq "AttributeTypeDescription" -and $AttributeName -eq "Name" -and $AttributeValue -eq "Visa"
            } -Exactly 1
        }

        It "Get-FimObjectId get correct parameters for variables objId" {
            Assert-MockCalled Get-FimObjectID -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
                $ObjectType -eq "ObjectTypeDescription" -and $AttributeName -eq "Name" -and $AttributeValue -eq "Person"
            } -Exactly 1
        }

        It "Remove-FimOject send correct parameters" {
            Assert-MockCalled Remove-FimObject -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
                $AnchorName -eq "ObjectID" -and $ObjectType -eq "BindingDescription"
                $AnchorValue | Should be "/BindingDescription[BoundAttributeType='AttributeTypeDescription Name Visa' and BoundObjectType='ObjectTypeDescription Name Person']"
            }
        }
    }
}


#Set-ExecutionPolicy -Scope process Unrestricted