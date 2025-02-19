provider "aws" {
  region = "eu-west-1"  # Change to your preferred AWS region
}

variable "ssh_public_key" {}

resource "aws_key_pair" "iss_data_fetcher_key" {
  key_name   = "iss_data_fetcher_key"  # Name of the key pair
  public_key = var.ssh_public_key
}

resource "aws_instance" "iss_data_fetcher" {
  ami           = "ami-0c55b159cbfafe1f0"  # Replace with a valid AMI ID
  instance_type = "t3.nano"

  tags = {
    Name = "iss-data-fetcher"
  }

  key_name        = aws_key_pair.iss_data_fetcher_key.key_name  # Use the created key pair
  security_groups = ["default"]  # Adjust security groups as needed
}

output "instance_ip" {
  value = aws_instance.iss_data_fetcher.public_ip
}
