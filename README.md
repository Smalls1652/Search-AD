# Search-AD

As it stands by default, if you use Get-ADUser or Get-ADComputer... You have to do a bit of a complicated search to actually get the data you want. This module is meant to simplify that by providing a cleaner parameter based structure to search AD.

## Requirements

This script should work out of the box for PowerShell 5.1 on Windows 10; however, **PowerShell Core** will require an external module to be installed called [PSCoreWindowsCompat](https://github.com/markekraus/PSCoreWindowsCompat). This is to bring back ADSI functionality for **PowerShell Core**. *This is not required for PowerShell 5.1!*

To install it, run this on your **PowerShell Core** console:
```powershell
Install-Module PSCoreWindowsCompat -Scope CurrentUser
```

## To-Do

- [x] Fallback on ADSI if Get-ADUser or Get-ADComputer are not found.
- [x] Add IP address searching through ADSI.
- [x] Remove the -Strict parameter.
- [x] Create .ps1xml file for formatting the output as a table by default.
- [x] Added verbose logging when -Verbose is utilized. 

## Command Help Files

### Search-ADUser

```powershell
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
```

### Search-ADComputer

```powershell
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
```