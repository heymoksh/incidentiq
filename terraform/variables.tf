variable "project" {
  description = "Project name used for naming and tagging"
  type        = string
  default     = "incidentiq"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region (Learner Lab supports us-east-1)"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile holding the Learner Lab session credentials"
  type        = string
  default     = "default"
}

variable "instance_type" {
  description = "EC2 size: t3.medium (4 GiB) runs Jenkins and the Docker containers"
  type        = string
  default     = "t3.medium"
}

variable "root_volume_gb" {
  description = "Root EBS volume size"
  type        = number
  default     = 20
}

variable "ssh_ingress_cidrs" {
  description = "CIDRs allowed to SSH. Ansible connects over SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "monitoring_ingress_cidrs" {
  description = "CIDRs allowed to reach Jenkins (8080)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
