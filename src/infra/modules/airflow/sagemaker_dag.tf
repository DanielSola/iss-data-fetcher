resource "aws_s3_object" "sagemaker_dag" {
    bucket = aws_s3_bucket.airflow.bucket
    key = "airflow/dag/sagemaker_train.py"
    source = local.sagemaker_train_dag_path
    etag = filemd5("${local.sagemaker_train_dag_path}")
}

resource "aws_s3_object" "merge_data_dag" {
    bucket = aws_s3_bucket.airflow.bucket
    key = "airflow/dag/merge_data_dag.py"
    source = local.merge_data_dag_path
    etag = filemd5("${local.merge_data_dag_path}")
}