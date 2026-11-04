# incidentIQ – Cloud-Native Incident Management System

Mini project · Moksh Jain (RA2311003010474) · Sanvi Soneji (RA2311003010444)

incidentIQ lets a team report IT incidents, get an automatic severity suggestion (P1–P4), track them through
Open → Investigating → Resolved with a timeline, and see live stats (open incidents, open P1s, mean time to resolve).

## DevOps toolchain

| Tool | Role |
|---|---|
| **AWS** (EC2, VPC, Security Group, Elastic IP) | Hosts Jenkins and the application |
| **Git / GitHub** | Source control; Jenkins polls the `main` branch |
| **Jenkins** | CI/CD pipeline: tests → Docker build → container smoke test → deploy → verify |
| **Docker** | Packages the app; data kept on the `incidentiq-data` volume |
| **Terraform** | Creates the EC2 instance, security group, key pair and Elastic IP |
| **Ansible** | Installs Docker and Jenkins (configuration as code) on the instance |

## Run
```
powershell -ExecutionPolicy Bypass -File .\scripts\run-all.ps1
```
Clean up: `.\scripts\99-destroy.ps1`
