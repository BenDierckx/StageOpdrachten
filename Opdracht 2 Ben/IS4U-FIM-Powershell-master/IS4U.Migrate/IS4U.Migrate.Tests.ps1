Import-Module IS4U.MigrateJson

# Set-ExecutionPolicy -Scope Process Unrestricted

Describe "Testing compare-objects" {

    $path = Select-FolderDialog

    $Array1 = @(
        [PSCustomObject]@{
            Name = "Test1"
            Rank = "User"
            ObjectType = "Person"
            ObjectID = [PSCustomObject]@{
                Value = "1"
            }
        },

        [PSCustomObject]@{
            Name = "Test2"
            Rank = "Admin"
            ObjectType = "Person"
            ObjectID = [PSCustomObject]@{
                Value = "2"
            }
        }
    )

    $Array2 = @(
        [PSCustomObject]@{
            Name = "Test1"
            Rank = "Admin"
            ObjectType = "Person"
            ObjectID = [PSCustomObject]@{
                Value = "1"
            }
        },

        [PSCustomObject]@{
            Name = "Test2"
            Rank = "Admin"
            ObjectType = "Person"
            ObjectID = [PSCustomObject]@{
                Value = "2"
            }
        }
    )

    Compare-MimObjects -ObjsSource $array1 -ObjsDestination $array2 -Anchor Name -path $path
    
}


Import-Module IS4U.Migrate
# Navigate to the "/IS4U.Migrate" folder
# Start tests with PS> Invoke-Pester 
Describe "Start-Migration export"{
    Mock Get-SchemaConfigToXml -ModuleName IS4U.Migrate
    Mock Get-PortalConfigToXml -ModuleName IS4U.Migrate
    Mock Get-PolicyConfigToXml -ModuleName IS4U.Migrate
    Mock Write-Host -ModuleName "IS4U.Migrate"
    context "With parameter ExportMIMToXml and user chooses 'y'"{
        Mock Read-Host {return "y"} -ModuleName "IS4U.Migrate"
        Start-Migration -ExportMIMToXml $True
        it "Start Migration calls correct functions when ExportMIMToXml param is True" {
            Assert-MockCalled Get-PolicyConfigToXml -ModuleName "IS4U.Migrate"
            Assert-MockCalled Get-SchemaConfigToXml -ModuleName "IS4U.Migrate"
            Assert-MockCalled Get-PortalConfigToXml -ModuleName "IS4U.Migrate"
        }
    }
    Context "With parameter ExportMIMToXml and user chooses 'n'"{
        Mock Read-Host {return "n"} -ModuleName "IS4U.Migrate"
        Start-Migration -ExportMIMToXml $True
        it "Start-Migration will not export when user chooses 'n'" {
            Assert-MockCalled Get-PolicyConfigToXml -ModuleName "IS4U.Migrate" -Exactly 0
            Assert-MockCalled Get-SchemaConfigToXml -ModuleName "IS4U.Migrate" -Exactly 0
            Assert-MockCalled Get-PortalConfigToXml -ModuleName "IS4U.Migrate" -Exactly 0
        }
    }
}

Describe "Start-Migration import" {
    Mock Compare-Schema -ModuleName "IS4U.Migrate"
    Mock Compare-Policy -ModuleName "IS4U.Migrate"
    Mock Compare-Portal -ModuleName "IS4U.Migrate"
    Mock Import-Delta -ModuleName "IS4U.Migrate"
    Mock Select-FolderDialog {
        return "./testPath"
    } -ModuleName "IS4U.Migrate"
    Mock Start-Process -ModuleName "IS4U.Migrate"
    Mock Write-Host -ModuleName "IS4U.Migrate"
    context "No parameters"{
        Start-Migration
        it "Correct path gets send"{
            Assert-MockCalled Compare-Schema -ParameterFilter {
                $Path -eq "./testPath"
            } -ModuleName "IS4U.Migrate"
        }
        it "All compares get called once" {
            Assert-MockCalled Compare-Schema -ModuleName "IS4U.Migrate" -Exactly 1
            Assert-MockCalled Compare-Portal -ModuleName "IS4U.Migrate" -Exactly 1
            Assert-MockCalled Compare-Policy -ModuleName "IS4U.Migrate" -Exactly 1
        }
    }
    context "With parameter ImportSchema" {
        Start-Migration -ImportSchema $True
        it "Only Compare-Schema gets called" {
            Assert-MockCalled Compare-Schema -ModuleName "IS4U.Migrate" -Exactly 1
            Assert-MockCalled Compare-Portal -ModuleName "IS4U.Migrate" -Exactly 0
            Assert-MockCalled Compare-Policy -ModuleName "IS4U.Migrate" -Exactly 0
        }
    }
}

Describe "Compare-MimObjects" {
    Mock Write-ToXmlFile -ModuleName "IS4U.Migrate"
    Context "No differences in objects" {
        $objs1 = @(
            [PSCustomObject]@{
                Name = "AttrTest"
                ObjectID = "555"
                ObjectType = "AttributeTypeDescription"
            },
            [PSCustomObject]@{
                Name = "ObjTest"
                ObjectID = "456"
                ObjectType = "ObjectTypeDescription"
            },
            [PSCustomObject]@{
                Name = "Ttest"
                ObjectID = "123"
                ObjectType = "BindingDescription"
                BoundAttributeType = "555"
                BoundObjectType = "456"
            }
        )
        $objs2 = @(
            [PSCustomObject]@{
                Name = "AttrTest"
                ObjectID = "555"
                ObjectType = "AttributeTypeDescription"
            },
            [PSCustomObject]@{
                Name = "ObjTest"
                ObjectID = "456"
                ObjectType = "ObjectTypeDescription"
            },
            [PSCustomObject]@{
                Name = "Ttest"
                ObjectID = "123"
                ObjectType = "BindingDescription"
                BoundAttributeType = "555"
                BoundObjectType = "456"
            }
        )
        $global:bindings = @()
        Compare-MimObjects -ObjsSource $objs1 -ObjsDestination $objs2 -path "./testPath"
        It "No differences should be found" {
            Assert-MockCalled Write-ToXmlFile -ModuleName "IS4U.Migrate" -Exactly 0
        }
    }

    Context "Differences in objects" {
        $objs1 = @(
            [PSCustomObject]@{
                Name = "At"
                ObjectID = "555"
                ObjectType = "AttributeTypeDescription"
            },
            [PSCustomObject]@{
                Name = "ObjTest"
                ObjectID = "456"
                ObjectType = "ObjectTypeDescription"
            },
            [PSCustomObject]@{
                Name = "Ttest"
                ObjectID = "123"
                ObjectType = "BindingDescription"
                BoundAttributeType = "555"
                BoundObjectType = "456"
            }
        )
        $objs2 = @(
            [PSCustomObject]@{
                Name = "AttrTest"
                ObjectID = "555"
                ObjectType = "AttributeTypeDescription"
            },
            [PSCustomObject]@{
                Name = "Ob"
                ObjectID = "456"
                ObjectType = "ObjectTypeDescription"
            },
            [PSCustomObject]@{
                Name = "Ttest"
                ObjectID = "123"
                ObjectType = "BindingDescription"
                BoundAttributeType = "555"
                BoundObjectType = "456"
            }
        )
        Mock Write-Host -ModuleName "IS4U.Migrate"
        Compare-MimObjects -ObjsSource $objs1 -ObjsDestination $objs2 -path "./testPath"
        It "Differences should be found and Write-ToXmlFile is called with correct differences" {
            Assert-MockCalled Write-ToXmlFile -ModuleName "IS4U.Migrate" -Exactly 1 -ParameterFilter {
                $DifferenceObjects[0].Name -eq "At"
                $DifferenceObjects[0].ObjectID | Should be "555"
                $DifferenceObjects[1].Name | Should be "ObjTest"
                $DifferenceObjects[1].ObjectID | Should be "456"
            }
        }
        Remove-Variable bindings -Scope Global
    }
}