. "$PSScriptRoot\lib.ps1"
Start-Step '08-demo' 'Use the live app: report, investigate and resolve incidents'
$ip = Get-PublicIp
$base = "http://$ip"
function New-Incident($t, $d, $s, $r) {
    $body = @{ title = $t; description = $d; service = $s; reporter = $r } | ConvertTo-Json
    $i = Invoke-RestMethod "$base/api/incidents" -Method Post -ContentType 'application/json' -Body $body
    Write-Host ("created {0}  {1,-48} {2}  ({3})" -f $i.id, $i.title, $i.severity, $i.service)
    return $i
}
function Set-Incident($id, $body) { Invoke-RestMethod "$base/api/incidents/$id" -Method Patch -ContentType 'application/json' -Body ($body | ConvertTo-Json) | Out-Null }
$a = New-Incident 'Payments API is down for all users' 'Checkout returns HTTP 503 since 10:05' 'Payments' 'Moksh Jain'
$b = New-Incident 'Login page slow during peak hours' 'Users wait 8-10 seconds to sign in' 'Login / Auth' 'Sanvi Soneji'
$c = New-Incident 'Email notifications delayed for some users' 'Order confirmation emails arrive late' 'Email' 'Sanvi Soneji'
$d = New-Incident 'Database disk almost full' 'Primary DB volume at 91 percent' 'Database' 'Moksh Jain'
Start-Sleep -Seconds 2
Set-Incident $a.id @{ status = 'Investigating'; note = 'On-call engineer paged; payment gateway container restarting' }
Set-Incident $d.id @{ status = 'Investigating'; note = 'Old logs being archived to S3' }
Start-Sleep -Seconds 2
Set-Incident $d.id @{ status = 'Resolved'; note = 'Disk usage back to 54 percent' }
Set-Incident $c.id @{ status = 'Resolved'; note = 'Mail queue drained' }
Write-Host ''
Exec "curl.exe -s $base/api/stats"
End-Step 'Incidents created and updated through the live API'
Start-Process "$base/"
Save-Screenshot '08b-incidentiq-dashboard' 10
