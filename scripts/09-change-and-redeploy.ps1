. "$PSScriptRoot\lib.ps1"
Start-Step '09-build2' 'Continuous delivery: code change -> git push -> Jenkins build #2 -> new version live'
$ip = Get-PublicIp
$f = Join-Path $ProjectRoot 'app\public\index.html'
(Get-Content $f -Raw).Replace('<span>Cloud-Native Incident Management System</span>', '<span>Cloud-Native Incident Management System | v2</span>') | Set-Content $f -NoNewline -Encoding UTF8
Exec 'git add app/public/index.html'
Exec 'git commit -m "v2: show release number in header"' -AllowFail | Out-Null
Exec 'git push origin main'
Exec "curl.exe -s http://$ip/health"
$b = Invoke-JenkinsBuild 'incidentiq-pipeline'
Exec "curl.exe -s http://$ip/health"
if ($b.result -ne 'SUCCESS') { Save-Screenshot '09-build2-FAILED'; exit 1 }
End-Step "Build #$($b.number): new version live, incidents kept on the Docker volume"
Start-Process "http://${ip}:8080/job/incidentiq-pipeline/"
Save-Screenshot '09b-jenkins-stage-view' 15
Start-Process "http://${ip}/"
Save-Screenshot '09c-incidentiq-v2' 10
