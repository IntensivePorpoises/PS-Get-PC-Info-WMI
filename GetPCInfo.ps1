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
    $UpTime = (Get-Date) - ($Last_Boot)
    $UpTime_Formatted = "Uptime: " + $UpTime.Days + " days, " + $UpTime.Hours + " hours, " + $UpTime.Minutes + " minutes" 

    # And try to find out what OU the PC is in.
    Import-Module -Name ActiveDirectory -Cmdlet Get-ADComputer, Get-ADOrganizationalUnit;
    $PC_AD_Name = Get-ADComputer $PC_NAME;
    $OU = $PC_AD_Name.DistinguishedName.SubString($PC_AD_Name.DistinguishedName.IndexOf('OU='));

    # Display minimally formatted output
    Write-Output "Note: some info may not populate if this is run against the local PC"
    Write-Output "------------------------------------------------"
    Write-Output "$User is logged in"
    Write-Output "$UpTime_Formatted"
    Write-Output "------------------------------------------------"
    Write-Output "Hostname: $Server_Name"
    Write-Output ""
    Write-Output "PC group membership report on line below:"
    Write-Output "$OU"
    Write-Output "------------------------------------------------"
    Write-Output "$OS_Name $OS_Arch"
    Write-Output "Windows version $OS_Version"
    Write-Output "------------------------------------------------"
    Write-Output "RAM: $RAM MB"
    Write-Output "------------------------------------------------"
    Write-Output "OEM Serial/Service Tag: $Serial_Number"
    Write-Output "BIOS version: $BIOS_Version"
    Write-Output "SMBIOS version: $SMBIOSV"
    Write-Output "SMBIOS GUID: $SMBIOS_GUID"
    Write-Output "------------------------------------------------"

    # We need more than a nanosecond to read this, so we want it to pause before closing.
    Read-Host -Prompt "Press Enter to exit"
}

$PC_HostName=read-host "Enter computer name:"

getPCInfo $PC_HostName
