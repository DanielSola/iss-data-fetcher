locals {
    sagemaker_train_dag_path = "${path.root}/../sagemaker_train.py"
    merge_data_dag_path = "${path.root}/../merge_data_dag.py"
}

variable "ami" {
  description = "The AMI to use for the instance"
  type        = string
}

variable "instance_type" {
  description = "The type of instance to start"
  type        = string
}
