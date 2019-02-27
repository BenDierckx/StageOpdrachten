Import-Module IS4U.FimPortal.Schema

Class NewFimImportObject {
    [string]$ObjectType #= "AttributeTypeDescription"
    [string]$State #= "Create"
    [Hashtable]$Changes = @{"Name" = "Visa"; "DisplayName" = "Visa"; "Type" = "String"; "MultiValued" = "False"}
    #[ImportObject]$ImportObject = [ImportObject]::new()
    NewFimImportObject($objectType, $State, $changes) {
        $this.ObjectType = $objectType
        $this.State = $State
        $this.Changes = $changes
    }
}

Class ImportObject {
    [string]$SourceObjectIdentifier
    [string]$TargetObjectIdentifier
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

        It "New-FimImportObject get called" {
            $changes = @{}
            $newFimImpObj = [NewFimImportObject]::new("AttributeTypeDescription", "Create", $changes)
            #$newFimImpObj.ImportObject.TargetObjectIdentifier = 1
            #$newFimImpObj.ImportObject.SourceObjectIdentifier = 5
            New-Attribute -Name Visa -DisplayName Visa -Type String -MultiValued "False"
            Mock New-FimImportObject {return $newFimImpObj}
            # is dit ok?
            New-FimImportObject -ObjectType AttributeTypeDescription -State Create -Changes $changes -ApplyNow -SkipDuplicateCheck -PassThru
            Assert-MockCalled -CommandName New-FimImportObject
        }
        
        It "Parameters get saved into object (Name, DisplayName, Type (mandatory), Description, MultiValued (Optional)" {
            $changes = @{}
            $newFimImpObj = [NewFimImportObject]::new("AttributeTypeDescription", "Create", $changes)
            Mock New-FimImportObject { return $newFimImpObj }
            $result = New-Attribute -Name Visa -DisplayName Visa -Type String -MultiValued "False"
            Write-Host($result)
            $result.Changes -eq @{"Name" = "Visa"; "DisplayName" = "Visa"; "Type" = "String"} | Should be $true
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