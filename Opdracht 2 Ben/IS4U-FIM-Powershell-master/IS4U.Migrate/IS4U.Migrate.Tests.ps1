Import-Module IS4U.Migrate

# Set-ExecutionPolicy -Scope Process Unrestricted

Describe "Write-ToXmlFile" {
    Context "With parameter" {
        Mock Search-Resources {
            $obj = @(
                [PsCustomObject] @{
                Name = "Testing"
                DisplayName = "TestingDisplay"
                Test = "final"
                ObjectID = "e0596263-8f1c-4ab1-8415-d73a1bedc222"
                },
                [PsCustomObject] @{
                Name = "Testing3"
                DisplayName = "TestingDisplay2"
                Test = "Final2"
                BoundAttributeType = "e0596263-8f1c-4ab1-8415-d73a1bedc222"
                ObjectID = New-Guid
                }
            )
            return $obj
        } -ModuleName "IS4U.Migrate"
        Write-ToXmlFile -ObjectType AttributeTypeDescription
        It "Search-Resources gets called using correct parameter" {
            Assert-MockCalled Search-Resources -ModuleName "IS4U.Migrate" -ParameterFilter {
                $XPath -eq "/AttributeTypeDescription"
                $ExpectedObjectType | Should be "AttributeTypeDescription"
            }
        }
        It "Write-ToXmlFile creates a xml file" {
            $file = ".\SourceAttributeTypeDescription.xml"
            $file | Should Exist
        }
    }
}

Describe "Get-SchemaConfig" {
    Mock Write-ToXmlFile {
        $file = Get-Content .\SourceAttributeTypeDescription.xml
        return $file
    } -ModuleName "IS4U.Migrate"
    Context "With existing xml file" {
        Get-SchemaConfig
        it "Write-ToXmlFile gets called 3 times" {
            Assert-MockCalled Write-ToXmlFile -ModuleName "IS4U.Migrate" -Exactly 3
        }
        It "Get-SchemaConfig creates a xml file" {
            $file = ".\SchemaConfigSource.xml"
            $file | Should Exist
        }
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