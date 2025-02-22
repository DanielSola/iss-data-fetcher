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

module "ec2_instance" {
  source        = "./modules/ec2-instance"
  ami           = "ami-0fc389ea796968582"
  instance_type = "t4g.nano"
  key_name      = "manual"
}

module "kinesis" {
  source        = "./modules/kinesis"
  stream_name   = "iss-data-stream"
}