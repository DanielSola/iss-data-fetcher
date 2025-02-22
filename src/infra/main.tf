terraform {
  backend "s3" {
    bucket         = "real-time-anomaly-detection-iss-terraform-state"
    key            = "terraform/state.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"  # Reference the table you just created
  }
}

provider "aws" {
  region = "eu-west-1"  # Change to your preferred AWS region
}

variable "ssh_public_key" {}

resource "aws_key_pair" "iss_data_fetcher_key" {
  key_name   = "iss_data_fetcher_key"  # Name of the key pair
  public_key = var.ssh_public_key

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_instance" "iss_data_fetcher" {
  ami           = "ami-0fc389ea796968582"
  instance_type = "t4g.nano"

  tags = {
    Name = "iss-data-fetcher"
  }

  key_name        = aws_key_pair.iss_data_fetcher_key.key_name  # Use the created key pair
  security_groups = ["default"]  # Adjust security groups as needed

  lifecycle {
    create_before_destroy = true  # Ensures the old instance is destroyed before creating a new one
  }
}

output "instance_ip" {
  value = aws_instance.iss_data_fetcher.public_ip
}
