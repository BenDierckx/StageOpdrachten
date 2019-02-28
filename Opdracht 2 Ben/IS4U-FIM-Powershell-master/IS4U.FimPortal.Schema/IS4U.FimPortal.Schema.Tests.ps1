Import-Module IS4U.FimPortal.Schema

Class NewFimImportObject {
    [string]$ObjectType #= "AttributeTypeDescription"
    [string]$State #= "Create"
    [Hashtable]$Changes = @{}
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
        Mock New-FimImportObject { $fimImport } -ModuleName "IS4U.FimPortal.Schema" -MockWith {$ObjectType, $State, $anchor, $changes, $ApplyNow}
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