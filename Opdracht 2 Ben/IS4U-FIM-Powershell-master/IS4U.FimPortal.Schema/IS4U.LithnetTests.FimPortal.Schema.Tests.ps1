Import-Module IS4U.FimPortal.Schema

Describe "New-Attribute" {
    Mock New-Resource {
        $test = [PSCustomObject]@{
            obj = @{
                DisplayName = ""
                Name = "" 
                Description = ""
                DataType = "" 
                MultiValued = ""
            }
        };
        #$test.obj.pstypenames.Insert(0, "Lithnet.ResourceManagement.Automation.RmaObject[]")
        return $test.obj
    } -ModuleName "IS4U.FimPortal.Schema"
    #Mock Save-Resource -ModuleName "IS4U.FimPortal.Schema"
    Context "With parameters" {
        $result = New-Attribute -Name Visa -DisplayName Visa -Type String -MultiValued "False"
        It "New-Resource gets called" {
            Assert-MockCalled New-Resource -ModuleName "IS4U.FimPortal.Schema" -Exactly 1
        }
        It "New-Resource gets correct parameters" {
            Assert-MockCalled New-Resource -ModuleName "IS4U.FimPortal.Schema" -ParameterFilter {
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
        $obj.psTypeNames.Insert(0, "Lithnet.ResourceManagement.Automation.RmaObject[]")
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
    Context "With parameters; Get-Resource returns a GUID" {
        Mock Get-Resource {New-Guid} -ModuleName "IS4U.fimPortal.Schema"
        $result = Update-Binding -AttributeName "Visa" -DisplayName "Visa Card Number"
    }
    Context "With parameters; Get-Resource returns an object"{
        Mock Get-Resource{
            [PSCustomObject]@{
                Required = ""
                DisplayName = ""
                Description = ""
            }
        } -ModuleName "IS4U.fimPortal.Schema"
        $result = Update-Binding -AttributeName "Visa" -DisplayName "Visa Card Number"
    }
}

#Set-ExecutionPolicy -Scope Process Unrestricted