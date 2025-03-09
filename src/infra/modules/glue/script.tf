resource "aws_s3_object" "glue_script" {
    bucket = var.bucket_name
    key = "glue/scripts/glue_script.py"
    etag = filemd5("${local.glue_src_path}")
}