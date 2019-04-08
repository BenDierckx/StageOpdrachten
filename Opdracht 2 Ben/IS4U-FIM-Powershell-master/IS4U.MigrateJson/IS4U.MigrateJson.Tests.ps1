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

    Compare-Objects -ObjsSource $array1 -ObjsDestination $array2 -Anchor Name -path $path
    
}