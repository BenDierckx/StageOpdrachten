Import-Module IS4U.FimPortal.Schema

Describe "New-Attribute" {
    Mock New-Resource {
        <#
            PSCustomObject is used here instead of New-MockObject.
            This is because New-MockObject only accepts the parameter -Type.
            PSCustomObject lets us return an object with variables that can be filled and tested.
        #>
        $test = [PSCustomObject]@{
                DisplayName = ""            #Empty values (not null) because Hashtable requires Keys that are set
                Name = ""                   #These get filled in the tested function
                Description = ""
                DataType = "" 
                MultiValued = ""
            }
        return $test
    } -ModuleName "IS4U.FimPortal.Schema"
    #Save-Resource can not be mocked when the required parameter is not of RmaObject type.
    #Mock Save-Resource -ModuleName "IS4U.FimPortal.Schema"
    Context "With parameters" {
        $result = New-Attribute -Name Visa -DisplayName Visa -Type String -MultiValued "False"
        It "New-Resource gets called" {
            Assert-MockCalled New-Resource -ModuleName "IS4U.FimPortal.Schema" -Exactly 1
        }
        It "New-Resource gets correct parameters" {
            Assert-MockCalled New-Resource -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
                #At least one -eq comparison has to be entered for the ParameterFilter work
                $ObjectType -eq "AttributeTypeDescription"
            }
        }
        It "obj gets filled and should be send to Save-Resource" {
            $result.DisplayName | Should be "Visa"
            $result.Name | Should be "Visa"
            $result.DataType | Should be "String"
            $result.MultiValued | Should be "False"
            $result.Description | Should beNullOrEmpty
        }
    }
}

Describe "Update-Attribute" {
    Mock Get-Resource {
        $obj = @{
            Name = ""
            DisplayName = ""
            Description = ""
        }
        #This does not work, only correct variables of a specific type can be inserted in a RmaObject
        #$obj.psTypeNames.Insert(0, "Lithnet.ResourceManagement.Automation.RmaObject[]")
        return $obj
    } -ModuleName "IS4U.FimPortal.Schema"
    Mock Save-Resource -ModuleName "IS4U.FimPortal.Schema"
    Context "With parameters" {
        $result = Update-Attribute -Name "Visa" -DisplayName "Visa" -Description "Visa card number"
        It "Get-Resource gets called" {
            Assert-MockCalled Get-Resource -ModuleName "IS4U.FimPortal.Schema" -Exactly 1
        }
        It "Get-Resource gets correct parameters" {
            Assert-MockCalled Get-Resource -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
                $ObjectType -eq "AttributeTypeDescription" -and $AttributeName -eq "Name"
                $AttributeValue | Should be "Visa"
            }
        }
        It "obj gets filled and should be send to Save-Resource" {
            $result.Name -eq "Visa"
            $result.DisplayName | Should be "Visa"
            $result.Description | Should be "Visa Card number"
        }
    }
}

Describe "Remove-Attribute" {
    Mock Get-Resource -ModuleName "IS4U.FimPortal.Schema"
    Mock Remove-Resource -ModuleName "IS4U.FimPortal.Schema"
    Context "With parameters" {
        Remove-Attribute -Name "Visa"
        It "Get-Resource gets correct parameters" {
            Assert-MockCalled Get-Resource -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
                $ObjectType -eq "AttributeTypeDescription" 
                $AttributeName | Should be "Name"
                $AttributeValue | Should be "Visa"
            }
        }
    }
}

Describe "New-Binding" {
    Mock Get-Resource { New-Guid } -ModuleName "IS4U.FimPortal.Schema"
    Mock New-Resource {
        $obj = [PSCustomObject]@{
            Required = ""
            DisplayName = ""
            Description = ""
            BoundAttributeType = "" 
            BoundObjectType = ""
            Id = ""
        }
        #$test.obj.pstypenames.Insert(0, "Lithnet.ResourceManagement.Automation.RmaObject[]")
        return $obj
    } -ModuleName "IS4U.FimPortal.Schema"
    Context "With parameters" {
        $result = New-Binding -AttributeName "Visa" -DisplayName "Visa Card Number"
        It "Get-Resource gets called 3 times" {
            Assert-MockCalled Get-Resource -ModuleName "IS4U.FimPortal.Schema" -Exactly 3
        }
        It "objId uses correct parameters for New-Resource" {
            Assert-MockCalled New-Resource -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
                $ObjectType -eq "BindingDescription"
            }
        }
        It "attrId and objId get a Guid from Get-Resource" {
            $result.BoundAttributeType.GetType() -eq [guid] | Should be $true
            $result.BoundObjectType.GetType() -eq [guid] | Should be $true
        }
        It "attrId uses correct parameters for Get-Resource" {
            Assert-MockCalled Get-Resource -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
                $ObjectType -eq "AttributeTypeDescription" -and $AttributeValue -eq "Visa"
            } -Exactly 1
        }
        It "objId uses correct parameters for Get-Resource" {
            Assert-MockCalled Get-Resource -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
                $ObjectType -eq "ObjectTypeDescription" -and $AttributeValue -eq "Person"
            } -Exactly 1
        }
        It "obj.id (id) sends correct parameters for Get-Resource" {
            $ObjectType -eq "BindingDescription" -and $AttributeValue -eq "Visa Card Number"
        }
    }
}

Describe "Update-Binding" {
    Context "With parameters; Get-Resource returns a guid 3 times and then an object" {
        <#  In Update-Binding (with Lithnet) the Get-Resource function gets called 4 times and
            requires 2 different returns (2 mocks would mean that the second mock will be
            ignored). For this we need a counter that gives a different return after so many calls  
        #>
        $Global:mockCounter = 0;                    #global variable so that it can be accessed in $mockTest
        $mockTest = {
            $Global:mockCounter++                   #Without global this variable would have not been set
            if ($mockCounter -le 3) {               #Get-Resource gets called 4 times (counter starts at 1) 
                return New-Guid                     #First 3 times Get-Resource returns a New-Guid (testing purposes)
            } else {
                $obj = [PSCustomObject]@{
                    Required = ""
                    DisplayName = ""
                    Description = ""
                }
                $mockCounter = 0;                   #Set mockCounter back to 0 when tests are completed and get repeated
                return $obj                         #After the 3rd call, Get-Resource returns a PsCustomObject
            }
        }
        #Use -MockWith on Get-Resource without {}, we want to return the return of the variable $mockTest
        #If {} is used the Mock will give a "variable not set" error
        Mock Get-Resource -ModuleName "IS4U.fimPortal.Schema" -MockWith $mockTest
        $result = Update-Binding -AttributeName "Visa" -DisplayName "Visa Card Number"
        It "Get-Resource gets called 4 times" {
            Assert-MockCalled Get-Resource -ModuleName "IS4U.FimPortal.Schema" -Exactly 4
        }
        It "Get-Resource uses correct parameters for variable attrId" {
            Assert-MockCalled Get-Resource -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
                $ObjectType -eq "AttributeTypeDescription" -and $AttributeValue -eq "Visa" -and $AttributesToGet -eq "ID"
            } -Exactly 1
        }
        It "Get-Resource uses correct parameters for variable objId" {
            Assert-MockCalled Get-Resource -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
                $ObjectType -eq "ObjectTypeDescription" -and $AttributeValue -eq "Person" -and $AttributesToGet -eq "ID"
            } -Exactly 1
        } 
        It "Get-Resource uses correct parameters for variable id" {
            Assert-MockCalled Get-Resource -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
                $ObjectType -eq "BindingDescription" -and $AttributeValuePairs.BoundAttributeType.GetType() -eq [guid] -and $AttributeValuePairs.BoundObjectType.GetType() -eq [guid] -and $AttributesToGet -eq "ID"
            } -Exactly 1
        }
        It "Get-Resource uses correct parameters for variable obj" {
            #Not possible to check if a New-Guid return is equal to an existing Guid
            #So check if the type is the same (should be if a Guid is returned)
            $result.GetType() -eq [UniqueIdentifier] | Should be $true
        }
    }
}

Describe "Remove-Binding" {
    Mock Get-Resource { 
        #Fixed Guid gets returned from Get-Resource only to check if variable $ID gets correct variable
        [Guid] "7d848959-d7b6-4162-a2ef-b0e037145c60" 
    } -ModuleName "IS4U.FimPortal.Schema"
    Mock Remove-Resource -ModuleName "IS4U.FimPortal.Schema"
    Context "With parameters" {
        Remove-Binding -AttributeName Visa
        It "Get-Resource gets called 4 times" {
            Assert-MockCalled Get-Resource -ModuleName "IS4U.FimPortal.Schema" -Exactly 3
        }
        It "Get-Resource uses correct parameters for variable attrId" {
            Assert-MockCalled Get-Resource -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
                $ObjectType -eq "AttributeTypeDescription" -and $AttributeValue -eq "Visa" -and $AttributesToGet -eq "ID"
            } -Exactly 1
        }
        It "Get-Resource uses correct parameters for variable objId" {
            Assert-MockCalled Get-Resource -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
                $ObjectType -eq "ObjectTypeDescription" -and $AttributeValue -eq "Person" -and $AttributesToGet -eq "ID"
            } -Exactly 1
        }
        It "Get-Resource uses correct parameters for variable id" {
            Assert-MockCalled Get-Resource -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
                $ObjectType -eq "BindingDescription" -and $AttributeValuePairs.BoundAttributeType.GetType() -eq [guid] -and $AttributeValuePairs.BoundObjectType.GetType() -eq [guid] -and $AttributesToGet -eq "ID"
            } -Exactly 1
        }
        It "Remove-Resource uses correct parameters" {
            Assert-MockCalled Remove-Resource -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
                $ID.Value -eq "7d848959-d7b6-4162-a2ef-b0e037145c60" | Should be $true
            }
        }
    }
}

#Set-ExecutionPolicy -Scope Process Unrestricted