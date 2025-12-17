#Created By Mason Cushing
#On 4-10-2025

#Install ExchangeOnlineManagement if it isn't already installed.
Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber

#Import the ExchangeOnlineManagement Module.
Import-Module ExchangeOnlineManagement

# Connect to Exchange Online. Replace with admin of whichever client you're impacting
Connect-ExchangeOnline -UserPrincipalName youradmin@yourdomain.com

# Define old and new domains
$oldDomain = "********"
$newDomain = "********"

# Get all mailboxes
$mailboxes = Get-Mailbox -ResultSize Unlimited

foreach ($mbx in $mailboxes) {
    $emailList = @()
    $primaryAddress = $null
    $newPrimarySet = $false

    # Find the current primary SMTP
    foreach ($addr in $mbx.EmailAddresses) {
        if ($addr.PrefixString -eq "SMTP") {
            $primaryAddress = $addr.SmtpAddress
            break
        }
    }

    # Only continue if the current primary ends with the old domain
    if ($primaryAddress -and $primaryAddress.EndsWith($oldDomain)) {
        $localPart = $primaryAddress.Split("@")[0]
        $newPrimary = "$localPart@$newDomain"

        foreach ($addr in $mbx.EmailAddresses) {
            if ($addr.PrefixString -eq "SMTP") {
                $emailList += "smtp:" + $addr.SmtpAddress  # Demote old primary to alias
            }
            elseif ($addr.PrefixString -eq "smtp" -and !$addr.SmtpAddress.EndsWith($newDomain)) {
                $emailList += $addr.ToString()  # Keep other aliases
            }
        }

        # Add new primary SMTP
        $emailList += "SMTP:" + $newPrimary
        $newPrimarySet = $true

        # Apply simulated change. When ready for final change REMOVE -WhatIf
        Set-Mailbox -Identity $mbx.Identity -EmailAddresses $emailList -WhatIf
    }

    # Flag the result
    if ($newPrimarySet) {
        Write-Output "✅ SUCCESS: $($mbx.Identity)'s primary SMTP changed to $newPrimary"
    } else {
        Write-Output "⚠️ SKIPPED: $($mbx.Identity) – No matching old primary SMTP found or already migrated"
    }
}

# Disconnect session
Disconnect-ExchangeOnline
