<#
        .SYNOPSIS
        Search for users in your Active Directory domain.

        .DESCRIPTION
        Search for users in your Active Directory domain and return the data in a quick and readable format that helpdesk users can use.

        .PARAMETER FirstName
        The first name of the user (Referred to as the GivenName in AD).

        .PARAMETER LastName
        The last name of the user (Referred to as the Surname in AD).

        .PARAMETER UserName
        The username of the user (Referred to as CN in AD).

        .PARAMETER Email
        The email address of the user (Referred to as EmailAddress in AD).

        .PARAMETER Strict
        Set this switch to make the search strict based. By default -like is used in the search.

        .EXAMPLE
        Search-ADUser -FirstName "John" -LastName "Doe"

        FirstName LastName UserName   Email
        --------- -------- --------   -----
        John      Doe      jdoe123    jdoe123@example.com

        .EXAMPLE
        Search-ADUser -FirstName "John" -LastName "Doe" | Select-Object -Property *

        FirstName         : John
        LastName          : Doe
        UserName          : jdoe123
        Email             : jdoe123@example.com
        LastLogon         : 9/4/2018 8:16:10 AM
        DistinguishedName : CN=jdoe123,CN=UsersDC=ad,DC=nashcc,DC=edu
        SID               : 
        Groups            : {CN=Domain Users,CN=Users,DC=ad,DC=example,DC=com}
#>
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