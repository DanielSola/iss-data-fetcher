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

resource "tls_private_key" "iss_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "iss_data_fetcher_key" {
  key_name   = "iss_data_fetcher_key"  # Name of the key pair
  public_key = tls_private_key.iss_ssh_key.public_key_openssh

  lifecycle {
    prevent_destroy = false
  }
}

module "ec2_instance" {
  source        = "./modules/ec2-instance"
  ami           = "ami-0fc389ea796968582"
  instance_type = "t4g.nano"
  key_name      = "manual"
}

output "instance_ip" {
  value = module.ec2_instance.instance_ip
}