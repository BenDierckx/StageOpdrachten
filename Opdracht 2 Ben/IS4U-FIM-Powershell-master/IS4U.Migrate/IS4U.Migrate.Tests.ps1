Import-Module IS4U.Migrate
# Navigate to the "/IS4U.Migrate" folder
# Start tests with PS> Invoke-Pester 
Describe "Export-MIMSetupToXml"{
    Mock Get-SchemaConfigToXml -ModuleName IS4U.Migrate
    Mock Get-PortalConfigToXml -ModuleName IS4U.Migrate
    Mock Get-PolicyConfigToXml -ModuleName IS4U.Migrate
    Mock Write-Host -ModuleName "IS4U.Migrate"
    context "With user chooses 'y'"{
        Mock Read-Host {return "y"} -ModuleName "IS4U.Migrate"
        Export-MIMSetupToXml
        it "Start Migration calls correct functions when ExportMIMToXml param is True" {
            Assert-MockCalled Get-PolicyConfigToXml -ModuleName "IS4U.Migrate"
            Assert-MockCalled Get-SchemaConfigToXml -ModuleName "IS4U.Migrate"
            Assert-MockCalled Get-PortalConfigToXml -ModuleName "IS4U.Migrate"
        }
    }
    Context "With user chooses 'n'"{
        Mock Read-Host {return "n"} -ModuleName "IS4U.Migrate"
        Export-MIMSetupToXml
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
        Start-Migration -All
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
    context "With parameter CompareSchema" {
        Start-Migration -CompareSchema
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