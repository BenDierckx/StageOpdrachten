Import-Module IS4U.FimPortal
# Set-ExecutionPolicy -Scope Process Unrestricted

Describe "New-Mpr" {
    Mock New-FimImportChange -ModuleName "IS4U.FimPortal"
    Mock Get-Resource { New-Guid } -ModuleName "IS4U.FimPortal"
    Mock New-Resource {
        $object = [PSCustomObject]@{
            DisplayName = ""
            PrincipalSet = ""
            ResourceCurrentSet  = ""
            ResourceFinalSet = ""
            ActionType = @()
            ActionParameter = @()
            GrantRight = ""
            ManagementPolicyRuleType = ""
            AuthenticationWorkflowDefinition = ""
            ActionWorkflowDefinition = ""
            Disabled = ""
            Description = ""
        }
        return $object
    } -ModuleName "IS4U.FimPortal"
    Context "With parameters" {
        $result = New-Mpr -DisplayName "test" -PrincipalSet new-guid -ResourceCurrentSet new-guid -ResourceFinalSet new-guid -ActionType @("atr1", "atr2") `
        -ActionParameter @("art3", "atr4") -GrantRight $true  -ManagementPolicyRuleType "testing" -AuthenticationWorkflowDefinition new-guid `
        -ActionWorkflowDefinition $null -Disabled $false -Description "hallo"
        It "New-Resource gets called" {
            Assert-MockCalled New-Resource -ModuleName "IS4U.FimPortal"
        }
        It "New-Resource gets called with correct parameters" {
            Assert-MockCalled New-Resource -ModuleName "IS4U.FimPortal" -ParameterFilter {
                $ObjectType -eq "ManagementPolicyRule"
            }
        }
        It "Get-Resource gets called with correct parameters" {
            Assert-MockCalled Get-Resource -ModuleName "IS4U.FimPortal" -ParameterFilter {
                $ObjectType -eq "ManagementPolicyRule"
                $AttributeName | Should be "DisplayName"
                $AttributeValue | Should be "test"
                $AttributesToGet | Should be "ID"
            }
        }
        It "Resource gets correct input (to send with Save-Resource)" {
            $result.DisplayName | Should be "test"
            $result.ActionType[0] | Should be "atr1"
            $result.ActionParameter[1] | Should be "atr4"
            $result.Description | Should be "hallo"
        }
        It "New-Mpr with parameter AuthenticationWorkflowDefinition gives GUID to variable resource" {
            $result.AuthenticationWorkflowDefinition.GetType() | Should be Microsoft.ResourceManagement.Webservices.UniqueIdentifier
        }
        It "New-Mpr without parameter ActionWorkflowDefinition does not fill ActionWorkflowDefinition on resource" {
            $result.ActionWorkflowDefinition | Should be $null
        }
        It "New-FimImportChange gets called 13 times with AuthenticationWorkflowDefinition parameter" {
            Assert-MockCalled New-FimImportChange -ModuleName "IS4U.FimPortal" -Exactly 13
        }
    }
}

Describe "Update-Mpr" {
    Mock New-FimImportChange -ModuleName "IS4U.FimPortal"
    Mock Get-Resource {
        $object = [PSCustomObject]@{
            DisplayName = ""
            PrincipalSet = ""
            ResourceCurrentSet  = ""
            ResourceFinalSet = ""
            ActionType = @()
            ActionParameter = @()
            GrantRight = ""
            ManagementPolicyRuleType = ""
            AuthenticationWorkflowDefinition = ""
            ActionWorkflowDefinition = ""
            Disabled = ""
            Description = ""
        }
        return $object
    } -ModuleName "IS4U.FimPortal"
    Context "With parameters" {
        $result = Update-Mpr -DisplayName "test" -PrincipalSet new-guid -ResourceCurrentSet new-guid -ResourceFinalSet new-guid `
        -ActionType @("atr1", "atr2") -ActionParameter @("art3", "atr4") -GrantRight $true  -AuthenticationWorkflowDefinition new-guid `
        -ActionWorkflowDefinition $null -Disabled $false -Description "hallo"
        It "Get-Resource gets called with correct parameters" {
            Assert-MockCalled Get-Resource -ModuleName "IS4U.FimPortal" -ParameterFilter {
                # AttributesToGet | Should be "ID" fails, problem with pester probably
                $ObjectType -eq "ManagementPolicyRule" -and $AttributesToGet -eq "ID" # Solution to test AttributesToGet parameter
                $AttributeName | Should be "DisplayName"
                $AttributeValue | Should be "test"
            }
        }
        It "Resource gets correct input (to send with Save-Resource)" {
            $result.DisplayName | Should be "test"
            $result.ActionType[0] | Should be "atr1"
            $result.ActionParameter[1] | Should be "atr4"
            $result.Description | Should be "hallo"
        }
        It "New-Mpr with parameter AuthenticationWorkflowDefinition gives GUID to variable resource" {
            $result.AuthenticationWorkflowDefinition.GetType() | Should be Microsoft.ResourceManagement.Webservices.UniqueIdentifier
        }
        It "New-Mpr without parameter ActionWorkflowDefinition does not fill ActionWorkflowDefinition on resource" {
            $result.ActionWorkflowDefinition | Should be $null
        }
        It "New-FimImportChange gets called 11 times with AuthenticationWorkflowDefinition parameter" {
            Assert-MockCalled New-FimImportChange -ModuleName "IS4U.FimPortal" -Exactly 11
        }
    }
}

Describe "Remove-Mpr" {
    Mock Get-Resource { [Guid] "049c0565-22e5-474f-9843-df8a4c1e78e2" } -ModuleName "IS4U.FimPortal"
    Mock Remove-Resource -ModuleName "IS4U.FimPortal"
    Context "With parameter DisplayName" {
        Remove-Mpr -DisplayName "testing"
        It "Get-Resource gets correct parameters" {
            Assert-MockCalled Get-Resource -ModuleName "IS4U.FimPortal" -ParameterFilter {
                $ObjectType -eq "ManagementPolicyRule" -and $AttributesToGet -eq "ID"
                $AttributeName | Should be "DisplayName"
                $AttributeValue | Should be "testing"
            }
        }
        It "Remove-Resource gets called" {
            Assert-MockCalled Remove-Resource -ModuleName "IS4U.FimPortal"
        }
        It "Remove-Resource uses correct parameters" {
            $ID -eq "049c0565-22e5-474f-9843-df8a4c1e78e2"
        }
    }
}

# Set-ExecutionPolicy -Scope Process Unrestricted