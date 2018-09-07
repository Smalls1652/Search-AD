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
        [string]$Email
    )

    function New-UserDataObject($UserData) {

        Update-FormatData -AppendPath "$($PSScriptRoot)\Search-ADUser.Format.ps1xml"

        $returnObj = New-Object -TypeName pscustomobject

        $defaultOutput = "FirstName", "LastName", "UserName", "Email", "PasswordLastSet"
        $defaultPropertSet = New-Object System.Management.Automation.PSPropertySet("DefaultDisplayPropertySet", [string[]]$defaultOutput)
        $CustomOutput = [System.Management.Automation.PSMemberInfo[]]@($defaultPropertSet)

        Add-Member -InputObject $returnObj -MemberType MemberSet -Name PSStandardMembers -Value $CustomOutput

        Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "FirstName" -Value "$($UserData.givenname)"
        Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "LastName" -Value "$($UserData.sn)"
        Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "UserName" -Value "$($UserData.cn)"
        Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "Email" -Value "$($UserData.mail)"
        Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "LastLogon" -Value ([datetime]::FromFileTime("$($UserData.lastlogon)"))
        Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "PasswordLastSet" -Value ([datetime]::FromFileTime("$($UserData.pwdlastset)"))
        Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "DistinguishedName" -Value "$($UserData.distinguishedname)"

        if (($UserData.objectsid | Get-Member).TypeName -eq "System.Security.Principal.SecurityIdentifier") {
            Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "SID" -Value $UserData.objectsid
        }
        else {
            Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "SID" -Value ([System.Security.Principal.SecurityIdentifier]"$((New-Object System.Security.Principal.SecurityIdentifier($UserData.objectsid[0], 0)).toString())")
        }

        Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "Groups" -Value $UserData.memberof

        Add-Member -InputObject $returnObj -TypeName Search.ActiveDirectory.Users

        return $returnObj
    }

    Write-Verbose "Setting search type to '-like'."
    $searchType = "-like"
    
    Write-Verbose "Creating searchObjects array."
    $searchObjects = @()
    if ($FirstName) {
        $searchObjects += @{"givenname" = $FirstName}
    }
    if ($LastName) {
        $searchObjects += @{"sn" = $LastName}
    }
    if ($UserName) {
        $searchObjects += @{"cn" = $UserName}
    }
    if ($Email) {
        $searchObjects += @{"userprinciplename" = $Email}
    }

    try {

        Write-Verbose "Trying to load Active Directory module..."

        Import-Module ActiveDirectory -ErrorAction Stop

        Write-Verbose "Using AD Module."

        $searchString = ""
        $i = 1

        foreach ($obj in $searchObjects) {
            $searchString += "$($obj.Keys) $($searchType) ""$($obj.Values)"""

            if ($i -ne $searchObjects.Count) {
                $searchString += " -and "
            }
            $i++
        }

        Write-Verbose "Filter set to '$($searchString)'."

        $adSearch = Get-ADUser -Filter $searchString -Properties *

    }
    catch {
        Write-Verbose "Active Directory module missing..."
        Write-Verbose "Using ADSI."

        if ($PSVersionTable.PSVersion.Major -ge 6) {
            Write-Verbose "PowerShell Core detected, loading PSCoreWindowsCompat."
            Import-Module PSCoreWindowsCompat -Force
        }

        Write-Verbose "Loading ADSI object."
        $adsiDomain = New-Object -TypeName DirectoryServices.DirectorySearcher
        $adsiDomain.Filter = '(&(objectCategory=user)'

        foreach ($obj in $searchObjects) {
            $adsiDomain.Filter += "($($obj.Keys)=$($obj.Values))"
        }

        $adsiDomain.Filter += ")"

        Write-Verbose "Filter set to '$($adsiDomain.Filter)'."
        
        $adSearch = $adsiDomain.FindAll().Properties

    }

    foreach ($user in $adSearch) {

        New-UserDataObject($user)

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
        [string]$IPAddress
    )

    function New-ComputerDataObject($CompData) {

        $returnObj = New-Object -TypeName pscustomobject

        Update-FormatData -AppendPath "$($PSScriptRoot)\Search-ADComputer.Format.ps1xml"

        $defaultOutput = "ComputerName", "IP Address", "Operating System", "LastLogon"
        $defaultPropertSet = New-Object System.Management.Automation.PSPropertySet("DefaultDisplayPropertySet", [string[]]$defaultOutput)
        $CustomOutput = [System.Management.Automation.PSMemberInfo[]]@($defaultPropertSet)

        Add-Member -InputObject $returnObj -MemberType MemberSet -Name PSStandardMembers -Value $CustomOutput

        Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "ComputerName" -Value "$($CompData.name)"

        if ($CompData.IPv4Address) {
            Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "IP Address" -Value $CompData.IPv4Address
        }
        else {
            try {
                $ipaddrRequest = ([system.net.dns]::GetHostEntry("$($CompData.dnshostname)")).AddressList | Where-Object -Property "AddressFamily" -eq "InterNetwork" | Select-Object -First 1 -ExpandProperty "IPAddressToString"
            }
            catch {
                $ipaddrRequest = ""
            }

            Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "IP Address" -Value $ipaddrRequest
        }
        
        Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "Operating System" -Value "$($CompData.operatingsystem)"
        Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "OS Version" -Value "$($CompData.operatingsystemversion)"
        Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "LastLogon" -Value ([datetime]::FromFileTime("$($CompData.lastlogon)"))
        Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "DistinguishedName" -Value "$($CompData.distinguishedname)"
        
        if (($CompData.objectsid | Get-Member).TypeName -eq "System.Security.Principal.SecurityIdentifier") {
            Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "SID" -Value $CompData.objectsid
        }
        else {
            Add-Member -InputObject $returnObj -MemberType NoteProperty -Name "SID" -Value ([System.Security.Principal.SecurityIdentifier]"$((New-Object System.Security.Principal.SecurityIdentifier($CompData.objectsid[0], 0)).toString())")
        }

        Add-Member -InputObject $returnObj -TypeName Search.ActiveDirectory.Computers

        return $returnObj
    }

    Write-Verbose "Setting search type to '-like'."
    $searchType = "-like"

    try {

        Write-Verbose "Trying to load Active Directory module..."

        Import-Module ActiveDirectory -ErrorAction Stop

        Write-Verbose "Using AD Module."

        Write-Verbose "Creating searchObjects array."
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
            $searchString += "$($obj.Keys) $($searchType) ""$($obj.Values)"""

            if ($i -ne $searchObjects.Count) {
                $searchString += " -and "
            }
            $i++
        }

        Write-Verbose "Filter set to '$($searchString)'."

        $adSearch = Get-ADComputer -Filter $searchString -Properties *

    }
    catch {

        Write-Verbose "Active Directory module missing..."
        Write-Verbose "Using ADSI."

        if ($PSVersionTable.PSVersion.Major -ge 6) {
            Write-Verbose "PowerShell Core detected, loading PSCoreWindowsCompat."
            Import-Module PSCoreWindowsCompat -Force
        }

        Write-Verbose "Converting IP Address to hostname."
        $IPAddress = [System.Net.Dns]::GetHostByAddress($IPAddress) | Select-Object -ExpandProperty "HostName"

        Write-Verbose "Creating searchObjects array."
        $searchObjects = @()
        if ($ComputerName) {
            $searchObjects += @{"Name" = $ComputerName}
        }
        if ($IPAddress) {
            $searchObjects += @{"dnshostname" = $IPAddress}
        }

        Write-Verbose "Loading ADSI object."
        $adsiDomain = New-Object -TypeName DirectoryServices.DirectorySearcher
        $adsiDomain.Filter = '(&(objectCategory=computer)'

        foreach ($obj in $searchObjects) {
            $adsiDomain.Filter += "($($obj.Keys)=$($obj.Values))"
        }

        $adsiDomain.Filter += ")"
        
        Write-Verbose "Filter set to '$($adsiDomain.Filter)'."

        $adSearch = $adsiDomain.FindAll().Properties

    }


    foreach ($comp in $adSearch) {

        New-ComputerDataObject($comp)

    }

}