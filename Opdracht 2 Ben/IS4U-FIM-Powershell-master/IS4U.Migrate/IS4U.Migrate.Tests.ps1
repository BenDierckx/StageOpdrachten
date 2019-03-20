Import-Module IS4U.Migrate

# Set-ExecutionPolicy -Scope Process Unrestricted

Describe "Write-ToCsv" {
    Context "With parameter" {
        $obj1 = [PSCustomObject]@{
            Name = "Test1"
            Value = "test1"
        }
        $obj2 = [PSCustomObject]@{
            Name = "Test2"
            Value = "test2"
        }
        $obj3 = [PSCustomObject]@{
            Name = "Test3"
            Value = "test3"
        }
        $obj4 = [PSCustomObject]@{
            Name = "Test4"
            Value = "test4"
        }
        $objs = @($obj1, $obj2, $obj3, $obj4)
        Write-Host $objs
        Write-ToCsv -Objects $objs -CsvName "Testing"
        $result = Get-ObjectsFromCsv -CsvFilePath "CsvConfigTesting.csv"
        Write-Host $result
    }
}

<#  
    - componenten maken, A component is a collection of resources such as sets,
     MPRs and workflows that come together to perform a particular function:
    * User Interface (RCDCs, Nav bar links, etc)
    * Schema (attributes, bindings, resource types)
    * Security model (permissions)
    * (SSPR)
    - ^ophalen gegevens uit fim
    - exporteren in delen naar xml of ander bestand?
    - 2 xml files genereren (origineel en met updates?)
    - Delta vergelijkt de 2
    - Delta met import-RmConfig (-preview om te zien wat er zou veranderen)
#>

# Set-ExecutionPolicy -Scope Process Unrestricted