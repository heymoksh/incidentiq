# incidentIQ end to end. Each step saves a screenshot to .\screenshots and a log to .\logs.
# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\run-all.ps1 [-From 05]
param([string]$From = '00')
$steps = @('00-preflight', '01-local-test', '02-git-push', '03-terraform-plan', '04-terraform-apply', '05-ansible-ping',
           '06-ansible-configure', '07-first-build', '08-demo-data', '09-change-and-redeploy', '10-aws-evidence')
foreach ($s in $steps) {
    if ($s.Substring(0, 2) -lt $From) { continue }
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "$s.ps1")
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Step $s failed (exit $LASTEXITCODE). Fix it, then resume with: -From $($s.Substring(0,2))" -ForegroundColor Red
        exit $LASTEXITCODE
    }
    Start-Sleep -Seconds 2
}
Write-Host 'ALL STEPS COMPLETE' -ForegroundColor Green
