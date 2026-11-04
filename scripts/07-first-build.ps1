. "$PSScriptRoot\lib.ps1"
Start-Step '07-build1' 'Jenkins build #1: test, build Docker image, deploy incidentIQ on EC2'
$b = Invoke-JenkinsBuild 'incidentiq-pipeline'
if ($b.result -ne 'SUCCESS') { Save-Screenshot '07-build1-FAILED'; exit 1 }
$ip = Get-PublicIp
Exec "curl.exe -s http://$ip/health"
End-Step "Build #$($b.number) deployed"
Start-Process "http://${ip}:8080/job/incidentiq-pipeline/"
Save-Screenshot '07b-jenkins-stage-view' 15
Start-Process "http://${ip}:8080/job/incidentiq-pipeline/lastSuccessfulBuild/console"
Save-Screenshot '07c-jenkins-console' 12
