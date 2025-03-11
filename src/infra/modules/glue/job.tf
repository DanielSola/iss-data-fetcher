resource "aws_glue_job" "merge_files_job" {
  name     = "merge-files-job"
  role_arn = aws_iam_role.glue_role.arn

  command {
    name            = "pythonshell"
    python_version  = "3.9"
    script_location = "s3://${var.bucket_name}/${var.script_path}"
  }

  default_arguments = {
    "--TempDir" = "s3://${var.bucket_name}/temp/"
    "--JOB_NAME" = "merge-files-job"
    "--enable-glue-detailed-logs" = "true"  # Enable detailed logs
  }

  max_capacity = 0.0625  # Minimum compute for Python Shell jobs
}