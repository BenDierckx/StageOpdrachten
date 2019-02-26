Import-Module IS4U.FimPortal.Schema

Class ImportObject {
    [string]$ObjectType
    [string]$State
    [Hashtable]$Changes
}

Describe "New-Attribute" {
    
    Context "Module Setup" {
        It "module file exists" {
            Get-Module -ListAvailable | Where {$_.Name -eq 'IS4U.FimPortal.Schema'}
        }
    }

    Context "With parameters (mandatory)" {
        It "Should return 1" {
            Mock New-Attribute -MockWith {return 1}
            $result = New-Attribute -Name Visa -DisplayName Visa -Type String -MultiValued "False"

            $result | Should be 1
        }
        
        It "Parameters get saved into object (Name, DisplayName, Type (mandatory), Description, MultiValued (Optional)" {
            Mock New-Attribute -MockWith {return 2}
            $result = New-Attribute -Name Visa -DisplayName Visa -Type String -MultiValued "False"
            New-Attribute $changes{} | Should MatchHashtable @{"Name" = "Visa"; "DisplayName" = "Visa"; "Type" = "String"}
        }
    }

    <#Context "with parameters (mandatory)" {
        Mock New-Atrribute {return 1}
        $result = New-Attribute -Name Visa -DisplayName Visa -Type String
            It "Name should be 'Visa'" {
                $actionResult = Get-Variable -Name $changes.Name
                $actionResult | should be "Visa"
            }
    }#>
}