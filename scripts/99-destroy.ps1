. "$PSScriptRoot\lib.ps1"
Start-Step '99-destroy' 'terraform destroy'
Exec 'terraform -chdir=terraform destroy -input=false -auto-approve'
End-Step 'All AWS resources destroyed'
