. "$PSScriptRoot\lib.ps1"
Start-Step '10-aws' 'AWS resources and server status'
Exec 'aws ec2 describe-instances --filters "Name=tag:Project,Values=incidentiq" "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].{Name:Tags[?Key==`Name`]|[0].Value,Id:InstanceId,Type:InstanceType,State:State.Name,PublicIP:PublicIpAddress}" --output table'
Exec 'aws ec2 describe-security-groups --filters "Name=group-name,Values=incidentiq-sg" --query "SecurityGroups[].IpPermissions[].{Port:FromPort,Source:IpRanges[0].CidrIp,Desc:IpRanges[0].Description}" --output table'
Invoke-Ansible 'status.yml'
End-Step 'AWS and Docker state captured'
Start-Process 'https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#Instances:'
Save-Screenshot '10b-aws-ec2-console' 20
Start-Process 'https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#SecurityGroups:'
Save-Screenshot '10c-aws-security-groups' 20
Start-Process 'https://github.com/heymoksh/incidentiq'
Save-Screenshot '10d-github-repo' 15
Start-Process 'https://github.com/heymoksh/incidentiq/commits/main'
Save-Screenshot '10e-github-commits' 12
