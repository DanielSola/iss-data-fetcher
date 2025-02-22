output "instance_ip" {
  value = module.ec2_instance.instance_ip
}

output "private_key" {
  value     = module.ec2_instance.private_key_pem
  sensitive = true
}