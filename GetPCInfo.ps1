function getPCInfo
{
Param($PCNAME)
    # I want some short neames to refer to these WMI objects by
    $PC_NAME = $PCNAME.Trim()
    $BIOS = Get-WmiObject win32_bios -comp $PC_NAME
    $OS = Get-WmiObject Win32_OperatingSystem -comp $PC_NAME
    $CS = Get-WmiObject Win32_ComputerSystem -comp $PC_NAME
    $CSP = Get-WmiObject Win32_ComputerSystemProduct -comp $PC_NAME

    # And to build these strings so the actual output commands don't have to be TOOOO ugly
    $Server_Name = $CS.DNSHostName+"."+$CS.Domain
    $Serial_Number = $BIOS.SerialNumber
    $BIOS_Version = $BIOS.Caption
    $SMBIOSV = $BIOS.SMBIOSBIOSVersion
    $SMBIOS_GUID = $CSP.UUID
    $Last_Boot = $OS.ConvertToDateTime($OS.LastBootUpTime)
    $OS_Name = $OS.Caption
    $OS_Arch = $OS.OSArchitecture
    $OS_Version = $OS.Version
    $User = $CS.UserName
    $RAM = ($CS.TotalPhysicalMemory/1MB).ToString(".")
    $Up_Time = (Get-Date) - ($Last_Boot)
    $Up_Time_Formatted = "Uptime: " + $Up_Time.Days + " days, " + $Up_Time.Hours + " hours, " + $Up_Time.Minutes + " minutes" 

    # And try to find out what OU the PC is in.
    Import-Module -Name ActiveDirectory -Cmdlet Get-ADComputer, Get-ADOrganizationalUnit;
    $PC_AD_Name = Get-ADComputer $PC_NAME;
    $OU = $PC_AD_Name.DistinguishedName.SubString($PC_AD_Name.DistinguishedName.IndexOf('OU='));

    # Display minimally formatted output
    Write-Output "Note: some info may not populate if this is run against the local PC"
    Write-Output "-------------------------------------"
    Write-Output "$User is logged in"
    Write-Output "$Up_Time_Formatted"
    Write-Output "-------------------------------------"
    Write-Output "Hostname: $Server_Name"
    Write-Output "$OU"
    Write-Output "$OS_Name| $OS_Arch | $OS_Version"
    Write-Output "-------------------------------------"
    Write-Output "RAM:$RAM MB"

    Write-Output "-------------------------------------"
    Write-Output "OEM Serial #: $Serial_Number"
    Write-Output "BIOS:$BIOS_Version"
    Write-Output "SMBIOS:$SMBIOSV"
    Write-Output "GUID: $SMBIOS_GUID"

    # We need more than a nanosecond to read this, so we want it to pause before closing.
    Read-Host -Prompt "Press Enter to exit"
}

$PC_AD_Name=read-host "Enter computer name:"

getPCInfo $PC_AD_Name
