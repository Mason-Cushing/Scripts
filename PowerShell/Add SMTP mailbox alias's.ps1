#Created by Mason Cushing
#On 4-2-25
#Modified 4-7-25

#Install ExchangeOnlineManagement if it isn't already installed.
Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber

#Import the ExchangeOnlineManagement Module.
Import-Module ExchangeOnlineManagement

#Connect to Exchange Online. Replace "******@yourdomain.com" with whatever admin account to the domain you're impacting. It will prompt you to login as the admin.
Connect-ExchangeOnline -UserPrincipalName ******@yourdomain.com

#Get all user mailboxes：
$mailboxes = Get-Mailbox -ResultSize Unlimited

#Loop through each mailbox and add the new aliases：

 foreach ($mailbox in $mailboxes)

 {

$newAlias1 = $mailbox.Alias + '@newdomain1.com'
$newAlias2 = $mailbox.Alias + '@newdomain2.com'


Set-Mailbox -Identity $mailbox.Identity -EmailAddresses @{add=$newAlias1,$newAlias2}

}