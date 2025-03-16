resource "aws_s3_bucket" "airflow" {
  bucket = "airflow-iss-anomaly-detector"
  force_destroy = true  # This ensures all objects are deleted before bucket removal

  tags = {
    Name  = "airflow-data"
  }
}
