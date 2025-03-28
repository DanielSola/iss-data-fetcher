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

module "kinesis" {
  source        = "./modules/kinesis"
  stream_name   = "iss-data-stream"
}

module "ec2_instance" {
  source        = "./modules/ec2-instance"
  ami           = "ami-0fc389ea796968582"
  instance_type = "t4g.nano"
  key_name      = "manual"
  iam_instance_profile = module.kinesis.ec2_instance_profile_name
}

module "data_bucket" {
  source = "./modules/data-bucket"
}

module "firehose" {
  source        = "./modules/firehose"
  input_kinesis_stream_arn = module.kinesis.stream_arn
  input_kinesis_stream_name = module.kinesis.stream_name
  destination_bucket_name = module.data_bucket.name
  destination_bucket_arn = module.data_bucket.arn
}

module "airflow" {
  source        = "./modules/airflow"
  ami           = "ami-03fd334507439f4d1"
  instance_type = "t2.small"
}