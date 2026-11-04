# Shared helpers for the PBL-II run scripts (Windows PowerShell 5.1+)
$ErrorActionPreference = 'Continue'
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $ProjectRoot
New-Item -ItemType Directory -Force (Join-Path $ProjectRoot 'logs') | Out-Null
New-Item -ItemType Directory -Force (Join-Path $ProjectRoot 'screenshots') | Out-Null

function Start-Step([string]$Id, [string]$Title) {
    $script:StepId = $Id
    $log = Join-Path $ProjectRoot "logs\$Id.log"
    try { Stop-Transcript | Out-Null } catch {}
    Start-Transcript -Path $log -Force | Out-Null
    Write-Host ''
    Write-Host ('=' * 78) -ForegroundColor DarkYellow
    Write-Host ("  incidentIQ  |  STEP $Id  |  $Title") -ForegroundColor Yellow
    Write-Host ("  " + (Get-Date -Format 'dd MMM yyyy HH:mm:ss') + "  |  " + $env:COMPUTERNAME) -ForegroundColor DarkGray
    Write-Host ('=' * 78) -ForegroundColor DarkYellow
}

function Exec([string]$Cmd, [switch]$AllowFail) {
    Write-Host ''
    Write-Host "PS> $Cmd" -ForegroundColor Cyan
    cmd /c "$Cmd 2>&1" | Out-Host
    $code = $LASTEXITCODE
    if ($code -ne 0 -and -not $AllowFail) {
        Write-Host "Command failed with exit code $code" -ForegroundColor Red
        Save-Screenshot "$($script:StepId)-FAILED"
        try { Stop-Transcript | Out-Null } catch {}
        exit $code
    }
    if ($AllowFail) { return $code }
}

function Invoke-Ansible([string]$Playbook, [string]$ExtraEnv = '') {
    Write-Host ''
    Write-Host 'PS> docker build -t obsidian-ansible ansible/  (Ansible control node)' -ForegroundColor Cyan
    cmd /c "docker image inspect obsidian-ansible:latest >nul 2>&1"
    if ($LASTEXITCODE -ne 0) {
        cmd /c "docker build -t obsidian-ansible:latest -f ansible\Dockerfile.controller ansible 2>&1" | Out-Host
        if ($LASTEXITCODE -ne 0) {
            Write-Host 'Controller build failed - falling back to the prebuilt alpine/ansible image' -ForegroundColor Yellow
            cmd /c "docker pull alpine/ansible:latest 2>&1" | Out-Host
            cmd /c "docker tag alpine/ansible:latest obsidian-ansible:latest 2>&1" | Out-Host
        }
    } else { Write-Host 'obsidian-ansible:latest already built' -ForegroundColor DarkGray }
    $envArgs = @('-e', 'ANSIBLE_HOST_KEY_CHECKING=False', '-e', 'ANSIBLE_FORCE_COLOR=1', '-e', 'ANSIBLE_CALLBACK_RESULT_FORMAT=yaml', '-e', 'ANSIBLE_DISPLAY_SKIPPED_HOSTS=False')
    if ($ExtraEnv) { $envArgs += @('-e', $ExtraEnv) }
    $inner = 'cp /work/ansible/keys/incidentiq.pem /root/key.pem && chmod 600 /root/key.pem && ' +
             "ansible-playbook -i inventory/hosts.ini -e ansible_ssh_private_key_file=/root/key.pem $Playbook"
    Write-Host "PS> ansible-playbook -i inventory/hosts.ini $Playbook" -ForegroundColor Cyan
    & docker run --rm @envArgs -v "${ProjectRoot}:/work" -w /work/ansible obsidian-ansible:latest sh -c $inner | Out-Host
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ansible-playbook failed ($LASTEXITCODE)" -ForegroundColor Red
        Save-Screenshot "$($script:StepId)-FAILED"
        try { Stop-Transcript | Out-Null } catch {}
        exit $LASTEXITCODE
    }
}

function Get-PublicIp {
    $ip = (cmd /c "terraform -chdir=terraform output -raw public_ip 2>nul")
    return "$ip".Trim()
}

function Save-Screenshot([string]$Name, [int]$Delay = 2) {
    Start-Sleep -Seconds $Delay
    Add-Type -AssemblyName System.Windows.Forms, System.Drawing
    if (-not ('DpiUtil' -as [type])) {
        Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public class DpiUtil { [DllImport("user32.dll")] public static extern bool SetProcessDPIAware(); }'
    }
    [DpiUtil]::SetProcessDPIAware() | Out-Null
    $b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($b.Location, [System.Drawing.Point]::Empty, $b.Size)
    $path = Join-Path $ProjectRoot "screenshots\$Name.png"
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    Write-Host "[screenshot] $path" -ForegroundColor DarkGray
}

function End-Step([string]$Message) {
    Write-Host ''
    Write-Host "  DONE  $Message" -ForegroundColor Green
    Write-Host ''
    Save-Screenshot $script:StepId 2
    try { Stop-Transcript | Out-Null } catch {}
}

function Get-JenkinsSession {
    $ip = Get-PublicIp
    $script:Jenkins = "http://${ip}:8080"
    $pw = (Get-Content (Join-Path $ProjectRoot 'ansible\keys\jenkins-admin-password.txt') -Raw).Trim()
    $auth = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("admin:$pw"))
    $script:JHeaders = @{ Authorization = $auth }
    $crumb = Invoke-RestMethod "$script:Jenkins/crumbIssuer/api/json" -Headers $script:JHeaders -SessionVariable sess
    $script:JSession = $sess
    $script:JHeaders[$crumb.crumbRequestField] = $crumb.crumb
}

function Invoke-JenkinsBuild([string]$Job) {
    Get-JenkinsSession
    $before = 0
    try { $before = (Invoke-RestMethod "$script:Jenkins/job/$Job/lastBuild/api/json?tree=number" -Headers $script:JHeaders -WebSession $script:JSession).number } catch {}
    Write-Host "PS> POST $script:Jenkins/job/$Job/build" -ForegroundColor Cyan
    Invoke-WebRequest "$script:Jenkins/job/$Job/build" -Method Post -Headers $script:JHeaders -WebSession $script:JSession -UseBasicParsing | Out-Null
    $b = $null
    for ($i = 0; $i -lt 360; $i++) {
        Start-Sleep -Seconds 5
        try { $b = Invoke-RestMethod "$script:Jenkins/job/$Job/lastBuild/api/json?tree=number,building,result,duration" -Headers $script:JHeaders -WebSession $script:JSession } catch { continue }
        if ($b.number -gt $before) {
            if (-not $b.building) { break }
            Write-Host ("  build #{0} running... {1}s" -f $b.number, ($i * 5))
        }
    }
    $d = Invoke-RestMethod "$script:Jenkins/job/$Job/$($b.number)/wfapi/describe" -Headers $script:JHeaders -WebSession $script:JSession
    Write-Host ''
    Write-Host ("Jenkins job {0}  build #{1}  ->  {2}" -f $Job, $b.number, $b.result) -ForegroundColor Yellow
    $d.stages | ForEach-Object { [pscustomobject]@{ Stage = $_.name; Status = $_.status; Seconds = [math]::Round($_.durationMillis / 1000, 1) } } | Format-Table -AutoSize | Out-Host
    return $b
}
