. "$PSScriptRoot\lib.ps1"
Start-Step '00-preflight' 'Toolchain and AWS Learner Lab credentials'
Exec 'terraform -version'
Exec 'docker version --format "Docker client {{.Client.Version}} / engine {{.Server.Version}}"'
Exec 'git --version'
Exec 'aws sts get-caller-identity --query "{Account:Account,Arn:Arn}" --output table'
Exec 'terraform fmt -recursive terraform'
End-Step 'Toolchain ready'
