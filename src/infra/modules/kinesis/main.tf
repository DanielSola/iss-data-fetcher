resource "aws_kinesis_stream" "iss_data_stream" {
  name        = var.stream_name

  retention_period = 24 # Data retention in hours (default is 24, max is 168)

  stream_mode_details {
    stream_mode = "ON_DEMAND"  # Choose "PROVISIONED" if you want manual scaling
  }

  tags = {
    Environment = "Production"
    Project     = "ISS-Tracking"
  }
}