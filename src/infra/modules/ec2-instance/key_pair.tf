resource "tls_private_key" "iss_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "iss_data_fetcher_key" {
  key_name   = "iss_data_fetcher_key"
  public_key = tls_private_key.iss_ssh_key.public_key_openssh

  lifecycle {
    prevent_destroy = false
  }
}

output "key_name" {
  value = aws_key_pair.iss_data_fetcher_key.key_name
}

output "private_key_pem" {
  value     = tls_private_key.iss_ssh_key.private_key_pem
  sensitive = true
}
