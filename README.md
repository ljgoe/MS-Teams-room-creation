<a name="readme-top"></a>
<!--

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://techblogwiki.azurewebsites.net">
    <img src="Images/logo.png" alt="Logo" width="80" height="80">
  </a>
  <h3 align="center">Create a Microsoft Teams Room Mailbox using powershell</h3>
</div>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#1-download-the-powershell-script-creatingteamsroomaccountps1">Download the powershell script</a></li>
    <li><a href="#2-connect-to-o365-and-exchange-online-with-your-tenant-admin-account">Connect to O365 and Exchange Online with your Tenant Admin Account</a></li>
    <li><a href="#3-get-the-meeting-room-license-sku">Get the Meeting Room License SKU</a></li>
    <li><a href="#4-set-the-variables-for-meeting-room-account">Set the variables for Meeting Room account</a></li>
    <li><a href="#5-create-a-mailbox-resource">Create The Resource Mailbox</a></li>
    <li><a href="#6-set-password-to-never-expire">Set password to never expire</a></li> 
  </ol>
</details>


<!-- GETTING STARTED -->
## Getting Started
### 1. Download the powershell script [CreatingTeamsRoomAccount.ps1](https://github.com/ljgoe/MS-Teams-room-creation/blob/main/CreatingTeamsRoomAccount.ps1)

> Install these optional modules if you have never connected to Office 365 / MS Online / Exchange Online

<!-- Optional Modules Table -->
<details>
  <summary>:arrow_up_down: **Expand to see Optional Modules to Install**</summary>
  <ol>

#### Optional Modules
* Skip publisher check 
```js
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12bInstall-Module PowerShellGet -RequiredVersion 2.2.4 -SkipPublisherCheck
```
* Install Nuget
```js
Install-PackageProvider -Name nuget -MinimumVersion 2.8.5.201 -force
```
* Install PnP.PowerShell with version 1.12.0 
```js
Install-Module -Name "PnP.PowerShell" -RequiredVersion 1.12.0 -Force -AllowClobber
```
* Module to connect to Azure AD / Azure Resource Manager
```js
Install-Module -Name AzureAD
Install-Module -Name Az -MinimumVersion 3.0.0 -AllowClobber -Scope AllUsers
```
* Other modules   
```js
Set-ExecutionPolicy RemoteSigned
Install-Module PowershellGet -Force
Update-Module PowershellGet
Install-Module -Name MSOnline –Force
import-Module MSOnline
Install-Module -Name ExchangeOnlineManagement
Import-Module ExchangeOnlineManagement
install-module AzureADPreview
```
<p align="right">(<a href="#readme-top">back to top</a>)</p>

</ol>
</details>

<!-- Script -->
### 2. Connect to O365 and Exchange Online with your Tenant Admin Account

> If you get an error "you must use multi-factor authentication to access XYZ"
> Then just issue the base command e.g "Connect-ExchangeOnline" and authenticate 
```js
$UserCredential = Get-Credential
Connect-MsolService -Credential $UserCredential
Connect-ExchangeOnline -Credential $UserCredential -ShowProgress $true
```
<p align="right">(<a href="#readme-top">back to top</a>)</p>

### 3. Get the Meeting Room License SKU
Set the licence SKU in the variable in the next step $license="xyz"

![Licence Check](Images/Images/licences.png)

```js
Get-MsolAccountSku
```
<p align="right">(<a href="#readme-top">back to top</a>)</p>

### 4. Set the variables for Meeting Room account
```js
$newRoom="MTR-DemoTeamsRoom@testit.vc"
$name="MTR-Demo"
$pwd="yourpassword"
$license="testitvideo:Microsoft_Teams_Rooms_Pro"
$location="AU"
```
<p align="right">(<a href="#readme-top">back to top</a>)</p>

### 5. Create a mailbox resource

Set the calendar processing with some key parameters and details
1. Setting AutomateProcessing to AutoAccept means that meetings will be processed and accepted automatically if there are no conflicts
2. Setting AddOrganizerToSubject to false ensures that the original subject is preserved and not replaced by the organizers’ name
3. Setting ProcessExternalMeetingMessages to true
3. Setting the RemovePrivateProperty to false ensures that the private flag for meeting requests is preserved (private meetings stay private)
4. Setting DeleteComments and DeleteSubject to false is critical and ensures that your meeting invitation has a “Join” button
5. The AdditionalResponse parameters are there to send useful information in the message back to the requester

```js
New-Mailbox -MicrosoftOnlineServicesID $newRoom -Name $name -Room -RoomMailboxPassword (ConvertTo-SecureString -String $pwd -AsPlainText -Force) -EnableRoomMailboxAccount $true
Start-Sleep -Seconds 31
Set-MsolUser -UserPrincipalName $newRoom -PasswordNeverExpires $true -UsageLocation $location
Set-MsolUserLicense -UserPrincipalName $newRoom -AddLicenses $license
Set-Mailbox -Identity $newRoom -MailTip “This room is equipped to support MS Teams Meetings”
Set-CalendarProcessing -Identity $newRoom -AutomateProcessing AutoAccept -AddOrganizerToSubject $false -ProcessExternalMeetingMessages $True -RemovePrivateProperty $false -DeleteComments $false -DeleteSubject $false -AddAdditionalResponse $true -AdditionalResponse “Your meeting is now scheduled and if it was enabled as a Teams Meeting will provide a seamless click-to-join experience from the conference room.”
```
<p align="right">(<a href="#readme-top">back to top</a>)</p>

### 6. Set password to never expire
```js
Set-MsolUser -UserPrincipalName $newRoom -PasswordNeverExpires $true
Get-MsolUser -UserPrincipalName $newRoom | Select PasswordNeverExpires
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>
<!-- Optional -->

### Optional
1. Use the Set-Place cmdlet to update room mailboxes with additional metadata, which provides a better search and room suggestion experience”

```js
Set-Place -Identity $newRoom -IsWheelChairAccessible $true -AudioDeviceName “Audiotechnica Wireless Mics” -VideoDeviceName “POLY STUDIO X70”
```
2. Meeting Room Voice Configuration
If you want the meeting room to be able to make calls to the PSTN you need to enable Enterprise Voice and configure a way for the user to place calls. 
If you’re using Calling Plans from Microsoft, you need to assign the user a calling plan license. 
If, on the other hand, you’re using Direct Routing through your own SBC or that of a Service Provider, you can grant the user account a Voice Routing Policy.

```js
Set-CsUser -Identity $newRoom -EnterpriseVoiceEnabled $true
Grant-CsOnlineVoiceRoutingPolicy -Identity $newRoom -PolicyName “Policy Name”
```
<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CHECK YOUR Settings that have been applied-->
### Check your new mailbox settings that have been applied

```js
Get-mailbox -Identity $newRoom | Fl
Get-Place -Identity $newRoom | Fl
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

