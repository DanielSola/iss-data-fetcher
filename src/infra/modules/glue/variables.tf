locals {
    glue_src_path = "${path.root}/../glue_script.py"
}

variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "script_path" {
  description = "Glue script path"
  type        = string
}