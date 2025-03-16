resource "aws_s3_object" "sagemaker_dag" {
    bucket = aws_s3_bucket.airflow.bucket
    key = "airflow/dag/sagemaker_train.py"
    source = local.sagemaker_train_dag_path
    etag = filemd5("${local.sagemaker_train_dag_path}")
}