# You can Skip any modules you already have installed, 
# I have found that on some new build PC's i have needed to run the extra comands
# Note that if you are having issues with your commands, Make sure you are using the x64 bit version of powershell running as admin

#### OPTIONAL #####
# Skip publicsher check 
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 
Install-Module PowerShellGet -RequiredVersion 2.2.4 -SkipPublisherCheck

# Install Nuget
Install-PackageProvider -Name nuget -MinimumVersion 2.8.5.201 -force

# Install PnP.PowerShell with version 1.12.0 
Install-Module -Name "PnP.PowerShell" -RequiredVersion 1.12.0 -Force -AllowClobber

# Install Module for Azure AD / Azure Resource Manager 
Install-Module -Name AzureAD
Install-Module -Name Az -MinimumVersion 3.0.0 -AllowClobber -Scope AllUsers

# Install additional Modules requried 
Set-ExecutionPolicy RemoteSigned
Install-Module PowershellGet -Force
Update-Module PowershellGet
Install-Module -Name MSOnline –Force
import-Module MSOnline
Install-Module -Name ExchangeOnlineManagement
Import-Module ExchangeOnlineManagement
install-module AzureADPreview

# Connect to M365 and Exchange Online with your Tenant Admin Account
# if you get an error like this "you must use multi-factor authentication to access XYZ"
# the just issue the base command e.g "Connect-ExchangeOnline" and authenticate 
$UserCredential = Get-Credential
Connect-MsolService -Credential $UserCredential
Connect-ExchangeOnline -Credential $UserCredential -ShowProgress $true


# Get the Meeting Room License SKU to use in the next step, $license="xyz"
# Mine is testitvideo:Microsoft_Teams_Rooms_Pro 
Get-MsolAccountSku

#Set the variables for Meeting Room account
$newRoom="MTR-DemoTeamsRoom@testit.vc"
$name="MTR-Demo"
$pwd="yourpassword"
$license="testitvideo:Microsoft_Teams_Rooms_Pro"
$location="AU"

# Create a mailbox resource

<# 
Set the calendar processing with some key parameters and details
1 - Set AutomateProcessing to AutoAccept - Meetings will be processed and accepted automatically if there are no conflicts
2 - Set AddOrganizerToSubject to false - Ensures that the original subject is preserved and not replaced by the organisers’ name
3 - Set ProcessExternalMeetingMessages to true - Allows users external to your company invite the room to a Teams meeting
4 - Set the RemovePrivateProperty to false - Ensures that the private flag for meeting requests is preserved (private meetings stay private)
5 - Set DeleteComments and DeleteSubject to false - This is critical and ensures that your meeting invitation has a “Join” button
6 - The AdditionalResponse parameters are there to send useful information in the message back to the requester
#> 

New-Mailbox -MicrosoftOnlineServicesID $newRoom -Name $name -Room -RoomMailboxPassword (ConvertTo-SecureString -String $pwd -AsPlainText -Force) -EnableRoomMailboxAccount $true
Start-Sleep -Seconds 31
Set-MsolUser -UserPrincipalName $newRoom -PasswordNeverExpires $true -UsageLocation $location
Set-MsolUserLicense -UserPrincipalName $newRoom -AddLicenses $license
Set-Mailbox -Identity $newRoom -MailTip “This room is equipped to support MS Teams Meetings”
Set-CalendarProcessing -Identity $newRoom -AutomateProcessing AutoAccept -AddOrganizerToSubject $false -ProcessExternalMeetingMessages $True -RemovePrivateProperty $false -DeleteComments $false -DeleteSubject $false -AddAdditionalResponse $true -AdditionalResponse “Your meeting is now scheduled and if it was enabled as a Teams Meeting will provide a seamless click-to-join experience from the conference room.”


# Set password to never expires

Set-MsolUser -UserPrincipalName $newRoom -PasswordNeverExpires $true
Get-MsolUser -UserPrincipalName $newRoom | Select PasswordNeverExpires

<# Optional
Use the Set-Place cmdlet to update room mailboxes with additional metadata, which provides a better search and room suggestion experience”
#>

Set-Place -Identity $newRoom -IsWheelChairAccessible $true -AudioDeviceName “Audiotechnica Wireless Mics” -VideoDeviceName “POLY STUDIO X70”

<# 
Meeting Room Voice Configuration
If you want the meeting room to be able to make calls to the PSTN you need to enable Enterprise Voice and configure a way for the user to place calls. 
If you’re using Calling Plans from Microsoft, you need to assign the user a calling plan license. 
If, on the other hand, you’re using Direct Routing through your own SBC or that of a Service Provider, you can grant the user account a Voice Routing Policy.
#>

Set-CsUser -Identity $newRoom -EnterpriseVoiceEnabled $true
Grant-CsOnlineVoiceRoutingPolicy -Identity $newRoom -PolicyName “Policy Name”


<#CHECK YOUR Settings that have been applied#>

Get-mailbox -Identity $newRoom | Fl
Get-Place -Identity $newRoom | Fl
