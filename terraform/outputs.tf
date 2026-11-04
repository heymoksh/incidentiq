output "instance_id" {
  value = aws_instance.web.id
}

output "public_ip" {
  value = aws_eip.web.public_ip
}

output "website_url" {
  value = "http://${aws_eip.web.public_ip}"
}

output "jenkins_url" {
  value = "http://${aws_eip.web.public_ip}:8080"
}
