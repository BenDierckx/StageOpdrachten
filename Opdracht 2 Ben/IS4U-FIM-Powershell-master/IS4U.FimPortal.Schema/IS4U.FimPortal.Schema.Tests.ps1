Import-Module IS4U.FimPortal.Schema

Class NewFimImportObject {
    [string]$ObjectType #= "AttributeTypeDescription"
    [string]$State #= "Create"
    [Hashtable]$Changes = @{}
    <#NewFimImportObject($objectType, $state, $changes) {
        $this.ObjectType = $objectType
        $this.State = $state
        $this.Changes = $changes
    }#>
}

<#Class ImportObject {
    [string]$SourceObjectIdentifier
    [string]$TargetObjectIdentifier
    [string]$ObjectType
    [string]$State
    [Hashtable]$Changes
}#>

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
            #New-FimImportObject -ObjectType AttributeTypeDescription -State Create -Changes $changes -ApplyNow -SkipDuplicateCheck -PassThru
            Assert-MockCalled -CommandName New-FimImportObject -ModuleName "IS4U.FimPortal.Schema"
        }
        
        It "Parameters get saved into object (Name, DisplayName, Type (mandatory), Description, MultiValued (Optional)" {
            Write-Host($result.changes)
            Assert-MockCalled New-FimImportObject -ParameterFilter{
                $changes["Name"] -eq "Visa" -and $changes["DisplayName"] -eq "Visa" -and $changes["DataType"] -eq "String"
            } -ModuleName "IS4U.FimPortal.Schema"
        }

        It "Return correct object" {
            Write-Host($result)
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