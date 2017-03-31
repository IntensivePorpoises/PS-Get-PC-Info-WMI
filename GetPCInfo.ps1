function getPCInfo
{
Param($PCNAME)
    # Import AD modules so we can use those
    Import-Module -Name ActiveDirectory -Cmdlet Get-ADComputer, Get-ADOrganizationalUnit, Get-ADUser;

    # I want some short neames to refer to these WMI objects by
    $PC_NAME = $PCNAME.Trim()
    $BIOS = Get-WmiObject win32_bios -comp $PC_NAME
    $OS = Get-WmiObject Win32_OperatingSystem -comp $PC_NAME
    $CS = Get-WmiObject Win32_ComputerSystem -comp $PC_NAME
    $CSP = Get-WmiObject Win32_ComputerSystemProduct -comp $PC_NAME
    $Net = Get-WmiObject Win32_NetworkAdapterConfiguration -comp  $PC_NAME


    # And to build these strings so the actual output commands don't have to be TOOOO ugly
    $User = $CS.UserName
    $Domain,$UserID=$User -split "\\"
    $Server_Name = $CS.DNSHostName+"."+$CS.Domain
    $Model = $CS.Model
    $IP_Address = ($Net | ? { $_.IPAddress -ne $null }).ipaddress
    $Serial_Number = $BIOS.SerialNumber
    $BIOS_Version = $BIOS.Version
    $BIOS_Caption = $BIOS.Caption
    $SMBIOSV = $BIOS.SMBIOSBIOSVersion
    $SMBIOS_GUID = $CSP.UUID
    $Last_Boot = $OS.ConvertToDateTime($OS.LastBootUpTime)
    $OS_Name = $OS.Caption
    $OS_Arch = $OS.OSArchitecture
    $OS_Version = $OS.Version
    $UserFName = (Get-Aduser $UserID -Properties GivenName).GivenName
    $UserLName = (Get-Aduser $UserID -Properties SurName).SurName
    $BoolAccountLocked = (Get-Aduser $UserID -Properties LockedOut).LockedOut
    $StrAccountLocked = "is NOT"
    $BoolAccountEnabled = (Get-Aduser $UserID -Properties Enabled).Enabled
    $StrAccountEnabled = "is NOT"
    $RAM = ($CS.TotalPhysicalMemory/1MB).ToString(".")
    $UpTime = (Get-Date) - ($Last_Boot)
    $UpTime_Formatted = "Uptime: " + $UpTime.Days + " days, " + $UpTime.Hours + " hours, " + $UpTime.Minutes + " minutes" 

    # Set up user status
    if($BoolAccountLocked)
    {
        $StrAccountLocked = "is"
    }

    if($BoolAccountEnabled)
    {
        $StrAccountEnabled = "is"
    }

    # And try to find out what OU the PC is in.
    $PC_AD_Name = Get-ADComputer $PC_NAME;
    $OU = $PC_AD_Name.DistinguishedName.SubString($PC_AD_Name.DistinguishedName.IndexOf('OU='));

    # Display minimally formatted output
    Write-Output ""
    Write-Output "Note: some info may not populate if this is run against the local PC"
    
    Write-Output "---- User info & uptime ---------------------------"
    Write-Output "$User ($UserFname $UserLName) is logged in"
    Write-Output ""
    Write-Output "Account $UserID $StrAccountLocked locked"
    Write-Output "Account $UserID $StrAccountEnabled enabled"
    Write-Output ""
    Write-Output "$UpTime_Formatted"
    Write-Output ""
    Write-Output "---- PC Name & Group Membership -------------------"
    Write-Output "Hostname: $Server_Name"
    Write-Output "Address(es): $IP_Address"
    Write-Output "PC's self-reported membership:"
    Write-Output "[$OU]"
    Write-Output ""
    Write-Output "---- Operating system Info-------------------------"
    Write-Output "$OS_Name $OS_Arch"
    Write-Output "Windows version $OS_Version"
    Write-Output ""
    Write-Output "---- Hardware -------------------------------------"
    Write-Output "Model: $Model"
    Write-Output "RAM: $RAM MB"
    Write-Output ""
    Write-Output "---- BIOS Information -----------------------------"
    Write-Output "OEM Serial/Service Tag: $Serial_Number"
    Write-Output "BIOS version: $BIOS_Version"
    Write-Output "BIOS caption below:"
    Write-Output "[$BIOS_Caption]"
    Write-Output "SMBIOS version: $SMBIOSV"
    Write-Output "SMBIOS GUID: $SMBIOS_GUID"
    Write-Output "---------------------------------------------------"

    # We need more than a nanosecond to read this, so we want it to pause before closing.
    Read-Host -Prompt "Press Enter to exit"
}

$PC_HostName=read-host "Enter computer name:"

getPCInfo $PC_HostName
