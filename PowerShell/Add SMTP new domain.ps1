#Created By Mason Cushing
#On 4-10-2025

#Install ExchangeOnlineManagement if it isn't already installed.
Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber

#Import the ExchangeOnlineManagement Module.
Import-Module ExchangeOnlineManagement

#Connect to Exchange Online. Replace with admin of whichever client you're impacting
Connect-ExchangeOnline -UserPrincipalName ADMIN@Domain.com

# Define new domains
$newDomain = "NewDOMAInN.com"

# Get all user mailboxes
$mailboxes = Get-Mailbox -ResultSize Unlimited

foreach ($mbx in $mailboxes) {
    $emailList = @()
    $newPrimarySet = $false
    $primaryString = ""

    try {
        # Get current primary SMTP safely
        if ($mbx.PrimarySmtpAddress -ne $null) {
            $primaryString = $mbx.PrimarySmtpAddress.ToString()
        }

        Write-Output "🔍 DEBUG: $($mbx.Identity) - Current Primary SMTP: $primaryString"

        if (![string]::IsNullOrWhiteSpace($primaryString) -and $primaryString.Contains("@")) {
            # Construct new primary email
            $localPart = $primaryString.Split("@")[0]
            $newPrimary = "$localPart@$newDomain"

            # Build new email list
            foreach ($addr in $mbx.EmailAddresses) {
                $addrStr = $addr.ToString().ToLower()

                # Demote current primary to alias
                if ($addrStr -eq "smtp:$primaryString".ToLower()) {
                    $emailList += "smtp:$primaryString"
                }
                # Keep all others, but skip if it matches the new primary (we'll re-add it as uppercase)
                elseif ($addrStr -ne "smtp:$newPrimary".ToLower()) {
                    $emailList += $addr.ToString()
                }
            }

            # Ensure the new primary SMTP is added as primary (uppercase SMTP:)
            $emailList += "SMTP:$newPrimary"
            $newPrimarySet = $true

            # Apply the updated list
            Set-Mailbox -Identity $mbx.Identity -EmailAddresses $emailList

            # Verify the change
            $updatedPrimary = (Get-Mailbox -Identity $mbx.Identity).PrimarySmtpAddress.ToString()
            Write-Output "🔁 VERIFY: $($mbx.Identity) new Primary SMTP is $updatedPrimary"
        } else {
            Write-Output "⚠️ SKIPPED: $($mbx.Identity) – No valid primary SMTP address"
        }
    } catch {
        Write-Output "❌ ERROR: $($mbx.Identity) – $($_.Exception.Message)"
    }

    if ($newPrimarySet) {
        Write-Output "✅ SUCCESS: $($mbx.Identity)'s primary SMTP updated to $newPrimary"
    } else {
        Write-Output "⚠️ SKIPPED: $($mbx.Identity) – No changes made"
    }
}

# Disconnect session
Disconnect-ExchangeOnline