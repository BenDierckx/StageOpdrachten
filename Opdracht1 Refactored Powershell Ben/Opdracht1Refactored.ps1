function GenerateAccount($firstName, $lastName) {
    #param([string]$firstName, [string]$lastName)
    set-variable -Name "FirstName" -value $FirstName.ToLower()
    $names = $lastName -split '\s+'
    if ($names.Count -ge 2) {
        set-variable -Name "LastName" -value $names[$names.Count -1].ToLower()
    }
    else {
        set-variable -Name "LastName" -value $lastName.ToLower()
    }

    if ($LastName.Length -ge 6){
        $account = $LastName.Substring(0,5) + $FirstName.Substring(0,1)
    }
    else {
        $account = $LastName.Substring(0, $LastName.Length) + $FirstName.Substring(0,1)
        $counter = 0
        while($account.Length -lt 6) {
            $account += $LastName[$counter]
            $counter++
            if ($counter -eq $LastName.Length) {
                $counter = 0
            }
        }
    }

    return $account
}
