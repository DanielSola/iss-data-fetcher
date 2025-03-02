resource "aws_kinesis_stream" "iss_data_stream" {
  name        = var.stream_name
  shard_count = 1

  retention_period = 24

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }

  tags = {
    Environment = "Production"
    Project     = "ISS-Tracking"
  }
}