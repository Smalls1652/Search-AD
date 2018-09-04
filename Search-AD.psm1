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
        DistinguishedName : CN=jdoe123,CN=Users,DC=ad,DC=example,DC=com
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

<#
        .SYNOPSIS
        Search for computers in your Active Directory domain.

        .DESCRIPTION
        Search for computers in your Active Directory domain and return the data in a quick and readable format that helpdesk users can use.

        .PARAMETER ComputerName
        The computer name of the computer (Referred to as the Name in AD).

        .PARAMETER IPAddress
        The IPv4 address of the computer (Referred to as the IPv4Address in AD).

        .PARAMETER Strict
        Set this switch to make the search strict based. By default -like is used in the search.

        .EXAMPLE
        Search-ADComputer -ComputerName "TestMach-01"

        ComputerName  IP Address    Operating System     LastLogon
        ------------  ----------    ----------------     ---------
        TestMach-01  192.168.1.5   Windows 10 Education 9/2/2018 2:47:47 PM

        .EXAMPLE
        Search-ADUser -IPAddress "192.168.1.5" | Select-Object -Property *

        ComputerName      : TestMach-01
        IP Address        : 192.168.1.5
        Operating System  : Windows 10 Education
        OS Version        : 10.0 (17134)
        LastLogon         : 9/2/2018 2:47:47 PM
        DistinguishedName : CN=TestMach-01,CN=Computers,DC=ad,DC=example,DC=com
        SID               : 
#>
function Search-ADComputer {

    [cmdletbinding()]
    param(
        [string]$ComputerName,
        [string]$IPAddress,
        [switch]$Strict
    )

    function New-ComputerDataObject($CompData) {

        $returnObj = New-Object -TypeName pscustomobject

        $returnObj.PSObject.TypeNames.Insert(0, "Search.ActiveDirectory.Computers")

        $defaultOutput = "ComputerName", "IP Address", "Operating System", "LastLogon"
        $defaultPropertSet = New-Object System.Management.Automation.PSPropertySet("DefaultDisplayPropertySet", [string[]]$defaultOutput)
        $CustomOutput = [System.Management.Automation.PSMemberInfo[]]@($defaultPropertSet)

        Add-Member -InputObject $returnObj -MemberType MemberSet -Name PSStandardMembers -Value $CustomOutput

        Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "ComputerName" -Value $CompData.Name
        Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "IP Address" -Value $CompData.IPv4Address
        Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "Operating System" -Value $CompData.OperatingSystem
        Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "OS Version" -Value $CompData.OperatingSystemVersion 
        Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "LastLogon" -Value $CompData.LastLogonDate
        Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "DistinguishedName" -Value $CompData.DistinguishedName
        Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "SID" -Value $CompData.SID

        return $returnObj
    }

    if ($Strict) {
        $searchType = "-eq"
    }
    else {
        $searchType = "-like"
    }

    $searchObjects = @()
    if ($ComputerName) {
        $searchObjects += @{"Name" = $ComputerName}
    }
    if ($IPAddress) {
        $searchObjects += @{"IPv4Address" = $IPAddress}
    }

    $searchString = ""
    $i = 1

    foreach ($obj in $searchObjects) {
        if ($obj.Keys -ne "IPv4Address") {
            $searchString += "$($obj.Keys) $($searchType) ""$($obj.Values)"""
        }
        else {
            $searchString += "$($obj.Keys) -eq ""$($obj.Values)"""
        }
            
        if ($i -ne $searchObjects.Count) {
            $searchString += " -and "
        }
        $i++
    }

    $adSearch = Get-ADComputer -Filter $searchString -Properties *

    foreach ($comp in $adSearch) {

        New-ComputerDataObject($comp)

    }

}