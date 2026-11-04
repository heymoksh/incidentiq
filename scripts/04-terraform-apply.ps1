. "$PSScriptRoot\lib.ps1"
Start-Step '04-terraform-apply' 'terraform apply - EC2 t3.medium, security group, key pair, Elastic IP'
Exec 'terraform -chdir=terraform apply -input=false tfplan'
Exec 'terraform -chdir=terraform output'
End-Step 'Infrastructure provisioned'
