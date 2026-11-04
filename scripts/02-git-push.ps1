. "$PSScriptRoot\lib.ps1"
Start-Step '02-git-push' 'Push the project to GitHub (heymoksh/incidentiq)'
$remote = 'https://github.com/heymoksh/incidentiq.git'
if (-not (Test-Path (Join-Path $ProjectRoot '.git'))) { Exec 'git init -b main' }
Exec 'git config user.name "Moksh Jain"'
Exec 'git config user.email "heymoksh@users.noreply.github.com"'
Exec 'git add -A'
Exec 'git commit -m "incidentIQ: incident management app, Dockerfile, Jenkinsfile, Terraform and Ansible"' -AllowFail | Out-Null
Exec 'git remote remove origin' -AllowFail | Out-Null
Exec "git remote add origin $remote"
Exec 'git push -u origin main'
Exec 'git log --oneline -3'
End-Step "Pushed to $remote"
