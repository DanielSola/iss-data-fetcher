output "instance_ip" {
  value = aws_instance.iss_data_fetcher.public_ip
}