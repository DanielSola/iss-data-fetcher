provider "aws" {
  region = "eu-west-1"  # Change to your preferred AWS region
}

resource "aws_key_pair" "iss-data-fetcher-key" {
  key_name   = "my-websocket-key"  # Name of the key pair
  public_key = file("~/.ssh/iss-data-fetcher.pub")  # Path to your public key
}

resource "aws_instance" "iss_data_fetcher" {
  ami           = "ami-0c55b159cbfafe1f0"  # Replace with a valid AMI ID
  instance_type = "t3.nano"

  tags = {
    Name = "iss-data-fetcher"
  }

  key_name        = "your-ssh-key"  # Replace with your EC2 key pair
  security_groups = ["default"]     # Adjust security groups as needed
}

output "instance_ip" {
  value = aws_instance.iss_data_fetcher.public_ip
}
