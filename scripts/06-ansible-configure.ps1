. "$PSScriptRoot\lib.ps1"
Start-Step '06-ansible-site' 'Ansible: install Docker and Jenkins (configuration as code) on the EC2 server'
Invoke-Ansible 'site.yml'
End-Step 'Server configured'
$ip = Get-PublicIp
Start-Process "http://${ip}:8080/"
Save-Screenshot '06b-jenkins-dashboard' 15
