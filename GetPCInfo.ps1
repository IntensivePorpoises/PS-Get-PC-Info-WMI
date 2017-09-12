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
    $DriveStats = Get-WMIObject Win32_DiskDrive -comp  $PC_NAME
    $Graphics = Get-WMIObject Win32_VideoController -comp $PC_NAME

    # Wait 1 sec
    Start-Sleep -s 1

    # I want to open the registry of the remote PC
    # So I create a hostname
    $HOSTNAME = '\\'+$PC_NAME

    # Wait 1 sec
    Start-Sleep -s 1

    # And I want to make sure the remote registry service is started (But not print status)
    sc.exe $HOSTNAME start "RemoteRegistry"  > $null

    # Wait 1 sec
    Start-Sleep -s 1

    # And I want to open HKLM on the remote PC:
    $RemoteRegistry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $PC_NAME)

    # Want to access specific info about Internet Explorer on the remote PC:
    $IEKey= $RemoteRegistry.OpenSubKey("SOFTWARE\\Microsoft\\Internet Explorer")

    # We want to get the name of the logged in user if there is one:
    # I want to check, first off, if there actually is someone logged in!
    if($CS.UserName)
    {
    # If so, we can start getting more info:
        $User = $CS.UserName
        $Domain,$UserID=$User -split "\\"
        $UserFName = (Get-Aduser $UserID -Properties GivenName).GivenName
        $UserLName = (Get-Aduser $UserID -Properties SurName).SurName
        $UserName = $UserFName + " " + $UserLName


		# Set up user status
		# Look to see if the user's account is enabled, and if it is locked
		$BoolAccountLocked = (Get-Aduser $UserID -Properties LockedOut).LockedOut
        $BoolAccountEnabled = (Get-Aduser $UserID -Properties Enabled).Enabled
        
		# Build strings based on the previous boolean values.
        #
        # Check if they're locked:
		if($BoolAccountLocked)
		{
			$StrAccountLocked = "Account $UserID is locked"
		}
		else
		{
			$StrAccountLocked = "Account $UserID is NOT locked"
		}
        # Check if they're enabled:
		if($BoolAccountEnabled)
		{
			$StrAccountEnabled = "Account $UserID is enabled"
		}
		else
		{
			$StrAccountEnabled = "Account $UserID is enabled"
		}

    }
    else
    {
    # If no user is logged on, print placeholder values instead of invalid ones.
        $UserName = "No user"
        $UserID = "No user"
        $User = "No user"
        $StrAccountLocked = ""
        $StrAccountEnabled = ""
    }


    # Build the strings that don't require any particular logic to them here
    # So the output commands do't have to be overly-complicated.
    
    $Server_Name = $CS.DNSHostName+"."+$CS.Domain
    $Model = $CS.Model
    #$GraphicsList = $Graphics.Name
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
    $IEVersion = $IEKey.GetValue("SvcVersion")
    $RAM = ($CS.TotalPhysicalMemory/1MB).ToString(".")
    $UpTime = (Get-Date) - ($Last_Boot)
    $UpTime_Formatted = "Uptime: " + $UpTime.Days + " days, " + $UpTime.Hours + " hours, " + $UpTime.Minutes + " minutes" 
    $DriveStatus = ""

    # Lets get a list of graphics cards on the system
    ForEach ($GPU in $Graphics.Name)
    {
        $GraphicsList = $GraphicsList + "$GPU`n"
    }

    # Create string w/ Drive list & statuses
    ForEach ($Drive in $DriveStats)
    {
        $DriveStatus = $DriveStatus + $Drive.Caption + ": " + $Drive.Status + "`n"
	}

    # And try to find out what OU the PC is in.
    $PC_AD_Name = Get-ADComputer $PC_NAME;
    $OU = $PC_AD_Name.DistinguishedName.SubString($PC_AD_Name.DistinguishedName.IndexOf('OU='));

    # Display minimally formatted output
    Write-Output ""
    Write-Output "Note: some info may not populate if this is run against the local PC"
    Write-Output "---- User info & uptime ---------------------------"
    Write-Output "$User ($UserName) is logged in"
    Write-Output ""
    Write-Output "$StrAccountLocked"
    Write-Output "$StrAccountEnabled"
    Write-Output ""
    Write-Output "$UpTime_Formatted"
    Write-Output ""
    Write-Output "---- PC Name & Group Membership -------------------"
    Write-Output "Hostname: $Server_Name"
    Write-Output "Address(es):"
    Write-Output "    $IP_Address"
    Write-Output ""
    Write-Output "PC's self-reported membership:"
    Write-Output "[$OU]"
    Write-Output ""
    Write-Output "---- Operating system Info-------------------------"
    Write-Output "$OS_Name $OS_Arch"
    Write-Output "Windows version $OS_Version"
    Write-Output ""
    Write-Output "Internet Explorer version $IEVersion"
    Write-Output ""
    Write-Output "---- Hardware -------------------------------------"
    Write-Output "Model: $Model"
    Write-Output "RAM: $RAM MB"
    Write-Output ""
    Write-Output "$GraphicsList"
    Write-Output ""
    Write-Output "$DriveStatus"
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
