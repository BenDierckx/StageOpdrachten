Import-Module IS4U.MigrateJson

# Navigate to the "/IS4U.MigrateJson" folder
# Start tests with PS> Invoke-Pester

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

    Compare-Objects -ObjsSource $array1 -ObjsDestination $array2 -Anchor Name -path $path  
}

Describe "Export-MIMSetupToJson export"{
    Mock Get-SchemaConfigToJson -ModuleName IS4U.MigrateJson
    Mock Get-PortalConfigToJson -ModuleName IS4U.MigrateJson
    Mock Get-PolicyConfigToJson -ModuleName IS4U.MigrateJson
    Mock Write-Host -ModuleName "IS4U.MigrateJson"
    context "With parameter ExportMIMToJson and user chooses 'y'"{
        Mock Read-Host {return "y"} -ModuleName "IS4U.MigrateJson"
        Export-MIMSetupToJson
        it "Start Migration calls correct functions when ExportMIMToJson param is True" {
            Assert-MockCalled Get-PolicyConfigToJson -ModuleName "IS4U.MigrateJson"
            Assert-MockCalled Get-SchemaConfigToJson -ModuleName "IS4U.MigrateJson"
            Assert-MockCalled Get-PortalConfigToJson -ModuleName "IS4U.MigrateJson"
        }
    }
    Context "With parameter ExportMIMToJson and user chooses 'n'"{
        Mock Read-Host {return "n"} -ModuleName "IS4U.MigrateJson"
        Export-MIMSetupToJson
        it "Start-MigrationJson will not export when user chooses 'n'" {
            Assert-MockCalled Get-PolicyConfigToJson -ModuleName "IS4U.MigrateJson" -Exactly 0
            Assert-MockCalled Get-SchemaConfigToJson -ModuleName "IS4U.MigrateJson" -Exactly 0
            Assert-MockCalled Get-PortalConfigToJson -ModuleName "IS4U.MigrateJson" -Exactly 0
        }
    }
}

Describe "Start-MigrationJson import" {
    Mock Compare-SchemaJson -ModuleName "IS4U.MigrateJson"
    Mock Compare-PolicyJson -ModuleName "IS4U.MigrateJson"
    Mock Compare-PortalJson -ModuleName "IS4U.MigrateJson"
    Mock Import-Delta -ModuleName "IS4U.MigrateJson"
    Mock Select-FolderDialog {
        return "./testPath"
    } -ModuleName "IS4U.MigrateJson"
    Mock Start-Process -ModuleName "IS4U.MigrateJson"
    Mock Write-Host -ModuleName "IS4U.MigrateJson"
    context "No parameters"{
        Start-MigrationJson
        it "Correct path gets send"{
            Assert-MockCalled Compare-SchemaJson -ParameterFilter {
                $Path -eq "./testPath"
            } -ModuleName "IS4U.MigrateJson"
        }
        it "All compares get called once" {
            Assert-MockCalled Compare-SchemaJson -ModuleName "IS4U.MigrateJson" -Exactly 1
            Assert-MockCalled Compare-PortalJson -ModuleName "IS4U.MigrateJson" -Exactly 1
            Assert-MockCalled Compare-PolicyJson -ModuleName "IS4U.MigrateJson" -Exactly 1
        }
    }
    context "With parameter ImportSchema" {
        Start-MigrationJson -CompareSchema
        it "Only Compare-SchemaJson gets called" {
            Assert-MockCalled Compare-SchemaJson -ModuleName "IS4U.MigrateJson" -Exactly 1
            Assert-MockCalled Compare-PortalJson -ModuleName "IS4U.MigrateJson" -Exactly 0
            Assert-MockCalled Compare-PolicyJson -ModuleName "IS4U.MigrateJson" -Exactly 0
        }
    }
}

Describe "Compare-Objects" {
    Mock Write-ToXmlFile -ModuleName "IS4U.MigrateJson"
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
        Compare-Objects -ObjsSource $objs1 -ObjsDestination $objs2 -path "./testPath"
        It "No differences should be found" {
            Assert-MockCalled Write-ToXmlFile -ModuleName "IS4U.MigrateJson" -Exactly 0
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
        Mock Write-Host -ModuleName "IS4U.MigrateJson"
        Compare-Objects -ObjsSource $objs1 -ObjsDestination $objs2 -path "./testPath"
        It "Differences should be found and Write-ToXmlFile is called with correct differences" {
            Assert-MockCalled Write-ToXmlFile -ModuleName "IS4U.MigrateJson" -Exactly 1 -ParameterFilter {
                $DifferenceObjects[0].Name -eq "At"
                $DifferenceObjects[0].ObjectID | Should be "555"
                $DifferenceObjects[1].Name | Should be "ObjTest"
                $DifferenceObjects[1].ObjectID | Should be "456"
            }
        }
        Remove-Variable bindings -Scope Global
    }
}

Describe "Write-ToXmlFile" {
    $path = (Get-PSDrive TestDrive).Root
    $objs = @([PSCustomObject]@{
                Name = "AttrTest"
                Attr = [System.Collections.ArrayList]@("test", "test2")
                ObjectType = "AttributeTypeDescription"}, 
                [PSCustomObject]@{
                Name = "ObjectTest"
                ObjectType = "ObjectTypeDescription"},
                [PSCustomObject]@{
                Name = "Ttest"
                ObjectType = "BindingDescription"})
    Context "With Anchor, custom objects and use of TestDrive:" {
        Write-ToXmlFile -path $path -DifferenceObjects $objs -Anchor @("Name")
        it "ConfigurationDelta.xml is created" {
            "TestDrive:\ConfigurationDelta.xml" | Should Exist
        }
        $content = [System.Xml.XmlDocument] (Get-Content "TestDrive:\ConfigurationDelta.xml")
        it "Xml-file has correct Lithnet structure"{
            # Initial structure
            $content."Lithnet.ResourceManagement.ConfigSync" | Should not benullorempty
            $content.'Lithnet.ResourceManagement.ConfigSync'.Operations | Should not benullorempty
            # ResourceOperation
            $resourceOp = $content.'Lithnet.ResourceManagement.ConfigSync'.Operations.ResourceOperation
            $resourceOp | Should not benullorempty
            $OperationOfResOp = $resourceOp[0]
            # Attributes of ResourceOperation
            $OperationOfResOp.operation | Should be "Add Update"
            $OperationOfResOp.resourceType | Should be "AttributeTypeDescription"
            # Anchor
            $OperationOfResOp.AnchorAttributes.AnchorAttribute | Should be "Name"  
        }
        it "File contains correct objects" {
            $objects = $content."Lithnet.ResourceManagement.ConfigSync".Operations.ResourceOperation.AttributeOperations
            $AttributeWithArray =  $objects[0].AttributeOperation
            # ArrayList test
            $AttributeWithArray[0].InnerText | Should be "AttrTest"
            $AttributeWithArray[1].InnerText | Should be "test"
            $AttributeWithArray[2].InnerText | Should be "test2"
            $AttrsOfNode = $AttributeWithArray | Select-Object operation
            # Attributes of xml object (with array) test
            $AttrsOfNode[0].operation | Should be "Replace"
            $AttrsOfNode[1].operation | Should be "Add"
            $AttrsOfNode[2].operation | Should be "Add"
            # Strings/objects test
            $objects[1].AttributeOperation.InnerText | Should be "ObjectTest"
            $objects[2].AttributeOperation.InnerText | Should be "Ttest"
            $xmlAttribute = $objects[0].AttributeOperation | Select-Object Name
            $xmlAttribute[0].name | Should be "Name"
        }
    }
}