Import-Module IS4U.Migrate

# Set-ExecutionPolicy -Scope Process Unrestricted

Describe "Compare-Objects" {
    $obj1 = @(
        [PSCustomObject]@{
            Name = "Value"
            Test = "test"
            ObjectType = "String"
            arry = @("m", "mm")
        },
        [PSCustomObject]@{
            Name = "Valu2"
            Test = "tes2"
            ObjectType = "int"
            arry = @("rt", "sd")
        }
    )

    $obj2 = @(
        [PSCustomObject]@{
            Name = "Value"
            Test = "test"
            ObjectType = "String"
            arry = @("m", "mm")
        },
        [PSCustomObject]@{
            Name = "Valu2"
            Test = "testt"
            ObjectType = "int"
            arry = @("addam", "ldld")
        }
    )

    Context "With parameters"{
        $diff = @()
        foreach ($member1 in $obj1){
            $member2 = $obj2 | Where-Object {$_.Name -eq $member1.Name}
            #if ($member2.psobject.properties.value -eq $member1.psobject.Properties.value) {
                write-host $member1.psobject.Properties.Value
                #write-host $member1prop.Value
            #}
       $test = Compare-Object -ReferenceObject $member1.psobject.members -DifferenceObject $member2.psobject.members -PassThru
       $testt = $test | Where-Object {$_.SideIndicator -eq '<='} # als originele anders is!
       $testt = $testt | Where-Object membertype -like 'noteproperty'
       $diff += $testt
       write-host "obj:"
       write-host $diff
       $newobj = [pscustomobject] @{}
       foreach($prop in $diff){
        $newobj | Add-Member -NotePropertyName $prop.Name -NotePropertyValue $prop.Value
       }    
       Write-Host $newobj
        }
    }
}

# Set-ExecutionPolicy -Scope Process Unrestricted