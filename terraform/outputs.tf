output "public_ip" {
  value = aws_instance.hello.public_ip
}

output "url" {
  value = "http://${aws_instance.hello.public_ip}/"
}

output "ssh" {
  value = var.admin_cidr == "" ? "SSH disabled" : "ssh -i ~/.ssh/msd_key ubuntu@${aws_instance.hello.public_ip}"
}
