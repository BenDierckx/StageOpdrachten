Describe "New-Attribute" {
    Mock New-Resource -ModuleName "IS4U.FimPortal.Schema" -MockWith {
        $DisplayName, $Name, $Description, $Type, $MultiValued
    }
    New-Attribute -Name "Visa" -DisplayName "Visa" -Type String -MultiValued "False"
    Mock Save-Resource -ModuleName "IS4U.FimPortal.Schema"
    Context "With parameters" {
        It "Save-Resource gets correct parameters" {
            Assert-MockCalled Save-Resource -ModuleName "IS4U.FimPortal.Schema" -Exactly 1
        }
    }
}

#Set-ExecutionPolicy -Scope process Unrestricted