. "$PSScriptRoot\lib.ps1"
Start-Step '03-terraform-plan' 'terraform init / validate / plan'
Exec 'terraform -chdir=terraform init -input=false -upgrade'
Exec 'terraform -chdir=terraform validate'
Exec 'terraform -chdir=terraform plan -input=false -out=tfplan'
End-Step 'Plan saved'
