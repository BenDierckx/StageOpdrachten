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

Describe "New-AttributeAndBinding" {
    Mock New-Binding -ModuleName "IS4U.FimPortal.Schema" -MockWith {
        $AttributeName, $DisplayName, $ObjectType
    } 
    
    Mock Add-AttributeToMPR -ModuleName "IS4U.FimPortal.Schema" -MockWith {
        $AttrName, $MprName
    }

    Mock Add-AttributeToFilterScope -ModuleName "IS4U.FimPortal.Schema" -MockWith {
        $AttributeId, $DisplayName
    }

    Mock New-Attribute { return New-Guid } -ModuleName "IS4U.FimPortal.Schema"

    Context "With parameters Name, DisplayName and Type to New-AttributeAndBinding" {
        New-AttributeAndBinding -Name "Visa" -DisplayName "Visa Card Number" -Type String
        It "New-Attribute sends correct parameters for variable attrId" {
            Assert-MockCalled New-Attribute -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
                $Name -eq "Visa" 
                $DisplayName -eq "Visa Card Number"
                $Type -eq "String"
            }
        }

        It "New-Attribute returns an UniqueIdentifier typ variable to attrId, this gets send with the correct DisplayName to Add-AttributeToFilterScope" {
            Assert-MockCalled Add-AttributeToFilterScope -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
                $AttributeId.GetType() -eq [Microsoft.ResourceManagement.WebServices.UniqueIdentifier]
                $DisplayName | Should be "Administrator Filter Permission"
            }
        }

        It "Add-AttributeToMPR gets called twice" {
            Assert-MockCalled Add-AttributeToMPR -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
                $AttrName -eq "Visa"
            } -Exactly 2
        }

        It "Default ObjectType variable (='Person') sends correct parameters to Add-AttributeToMPR first time" {
            Assert-MockCalled Add-AttributeToMPR -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
                $AttrName -eq "Visa" -and $MprName -eq "Administration: Administrators can read and update Users"
            } -Exactly 1
        }

        It "Default ObjectType variable (='Person') sends correct parameters to Add-AttributeToMPR second time" {
            Assert-MockCalled Add-AttributeToMPR -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
                $AttrName -eq "Visa" -and $MprName -eq "Synchronization: Synchronization account controls users it synchronizes"
            } -Exactly 1
        }
    }

    Context "With parameters Name, DisplayName, Type and ObjectType ('Group') to New-AttributeAndBinding" {
        New-AttributeAndBinding -Name "Visa" -DisplayName "Visa Card Number" -Type String -ObjectType Group
        It "Add-AttributeToMPR gets called twice" {
            Assert-MockCalled Add-AttributeToMPR -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
                $AttrName -eq "Visa"
            } -Exactly 2
        }

        It "Default ObjectType variable (='Group') sends correct parameters to Add-AttributeToMPR first time" {
            Assert-MockCalled Add-AttributeToMPR -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
                $AttrName -eq "Visa" -and $MprName -eq "Group management: Group administrators can update group resources"
            } -Exactly 1
        }

        It "ObjectType variable (='Group') sends correct parameters to Add-AttributeToMPR second time" {
            Assert-MockCalled Add-AttributeToMPR -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
                $AttrName -eq "Visa" -and $MprName -eq "Synchronization: Synchronization account controls group resources it synchronizes"
            } -Exactly 1
        }
    }
}

Describe "Remove-AttributeAndBinding" {
    Mock Remove-AttributeFromMPR -ModuleName "IS4U.FimPortal.Schema" -MockWith {
        $AttrName, $MprName
    }

    Mock Remove-AttributeFromFilterScope -ModuleName "IS4U.FimPortal.Schema" -MockWith {
        $AttributeName, $DisplayName
    }

    Mock Remove-Binding -ModuleName "IS4U.FimPortal.Schema" -MockWith {
        $AttributeName, $ObjectType
    }

    Mock Remove-Attribute -ModuleName "IS4U.FimPortal.Schema" -MockWith {
        $Name
    }

    Context "With parameters Name" {
        Remove-AttributeAndBinding -Name Visa
        It "Default objectType calls Remove-AttributeFromMPR two times" {
            Assert-MockCalled Remove-AttributeFromMPR -ModuleName "IS4U.FimPortal.Schema" -Exactly 2
        }

        It "Remove-AttributeFromMpr gets correct parameters first call" {
            Assert-MockCalled Remove-AttributeFromMPR -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
                $AttrName -eq "Visa" -and $MprName -eq "Administration: Administrators can read and update Users"
            } -Exactly 1
        }

        It "Remove-AttributeFromMpr gets correct parameters second call" {
            Assert-MockCalled Remove-AttributeFromMPR -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
                $AttrName -eq "Visa" -and $MprName -eq "Synchronization: Synchronization account controls users it synchronizes"
            } -Exactly 1
        }

        It "Remove-AttributeFromFilterScope sends correct parameters" {
            Assert-MockCalled Remove-AttributeFromFilterScope -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
                $AttributeName -eq "Visa" -and $DisplayName -eq "Administrator Filter Permission"
            }
        }

        It "Remove-Binding sends correct parameters" {
            Assert-MockCalled Remove-Binding -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
                $AttributeName -eq "Visa" -and $ObjectType -eq "Person"
            }
        }

        It "Remove-Attribute sends correct parameters" {
            Assert-MockCalled Remove-Attribute -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
                $Name -eq "Visa"
            }
        }
    }

    Context "With parameters Name and ObjectType ('Group')" {
        Remove-AttributeAndBinding -Name "Visa" -ObjectType "Group"
        It "Remove-AttributeFromMPR gets called 0 times" {
            Assert-MockCalled Remove-AttributeFromMPR -ModuleName "IS4U.FimPortal.Schema" -Exactly 0
        }

        It "Remove-Binding send correct parameters" {
            Assert-MockCalled Remove-Binding -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
                $AttributeName -eq "Visa" -and $ObjectType -eq "Group"
            }
        }
    }
}

#Set-ExecutionPolicy -Scope process Unrestricted