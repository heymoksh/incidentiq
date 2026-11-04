. "$PSScriptRoot\lib.ps1"
Start-Step '05-ansible-ping' 'Ansible connectivity check'
$ip = Get-PublicIp
Write-Host "Waiting for SSH on $ip ..." -ForegroundColor DarkGray
for ($i = 0; $i -lt 30; $i++) {
    $c = New-Object System.Net.Sockets.TcpClient
    try { $c.Connect($ip, 22); $c.Close(); break } catch { Start-Sleep -Seconds 5 }
}
Invoke-Ansible 'ping.yml'
End-Step "Ansible can manage $ip"
