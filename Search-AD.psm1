function Search-ADUser {

    [cmdletbinding()]
    param(
        [string]$FirstName,
        [string]$LastName,
        [string]$UserName,
        [string]$Email,
        [switch]$Strict
    )

    function New-UserDataObject {
        param(
            [Microsoft.ActiveDirectory.Management.ADUser]$UserData
        )

        $returnObj = New-Object -TypeName pscustomobject

        $returnObj.PSObject.TypeNames.Insert(0, "Search.ActiveDirectory.Users")

        $defaultOutput = "FirstName", "LastName", "UserName", "Email"
        $defaultPropertSet = New-Object System.Management.Automation.PSPropertySet("DefaultDisplayPropertySet", [string[]]$defaultOutput)
        $CustomOutput = [System.Management.Automation.PSMemberInfo[]]@($defaultPropertSet)

        Add-Member -InputObject $returnObj -MemberType MemberSet -Name PSStandardMembers -Value $CustomOutput

        Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "FirstName" -Value $user.GivenName
        Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "LastName" -Value $user.Surname
        Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "UserName" -Value $user.CN
        Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "Email" -Value $user.EmailAddress 
        Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "LastLogon" -Value $user.LastLogonDate
        Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "DistinguishedName" -Value $user.DistinguishedName
        Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "SID" -Value $user.SID
        Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "Groups" -Value $user.MemberOf

        return $returnObj
    }

    if ($Strict) {
        $searchType = "-eq"
    }
    else {
        $searchType = "-like"
    }


    $searchObjects = @()
    if ($FirstName) {
        $searchObjects += @{"GivenName" = $FirstName}
    }
    if ($LastName) {
        $searchObjects += @{"Surname" = $LastName}
    }
    if ($UserName) {
        $searchObjects += @{"CN" = $UserName}
    }
    if ($Email) {
        $searchObjects += @{"EmailAddress" = $Email}
    }

    $searchString = ""
    $i = 1
    
    foreach ($obj in $searchObjects) {
        $searchString += "$($obj.Keys) $($searchType) ""$($obj.Values)"""

        if ($i -ne $searchObjects.Count) {
            $searchString += " -and "
        }
        $i++
    }

    $adSearch = Get-ADUser -Filter $searchString -Properties *

    foreach ($user in $adSearch) {

        New-UserDataObject -UserDate $user

    }

}