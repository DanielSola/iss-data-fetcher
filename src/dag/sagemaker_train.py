from airflow import DAG
from airflow.providers.amazon.aws.operators.sagemaker import SageMakerTrainingOperator
from datetime import datetime, timedelta
import os
import uuid
from airflow.providers.amazon.aws.sensors.s3 import S3KeySensor

# DAG default arguments
default_args = {
    "owner": "airflow",
    "start_date": datetime(2025, 3, 17),
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}

# AWS & SageMaker Configuration
SAGEMAKER_ROLE_ARN = "arn:aws:iam::730335312484:role/service-role/AmazonSageMaker-ExecutionRole-20250317T121373"
TRAINING_IMAGE_URI = "438346466558.dkr.ecr.eu-west-1.amazonaws.com/randomcutforest:1"
S3_TRAINING_DATA = "s3://iss-historical-data/data/loop_A_flowrate.csv"
S3_OUTPUT_PATH = "s3://iss-historical-data/data/"

# Set region
os.environ['AWS_DEFAULT_REGION'] = 'eu-west-1'

def get_training_config(**context):

    JOB_NAME = f"TRAINING-JOB-{str(uuid.uuid4())[0:5]}"

    context['ti'].xcom_push(key='JOB_NAME', value=JOB_NAME)

    return {
            "TrainingJobName": JOB_NAME,  # DAG Run ID as part of the job name
            "AlgorithmSpecification": {
                "TrainingImage": TRAINING_IMAGE_URI,
                "TrainingInputMode": "File",
            },
            "RoleArn": SAGEMAKER_ROLE_ARN,
            "InputDataConfig": [
                {
                    "ChannelName": "train",
                    "DataSource": {
                        "S3DataSource": {
                            "S3DataType": "S3Prefix",
                            "S3Uri": S3_TRAINING_DATA,
                            "S3DataDistributionType": "ShardedByS3Key",
                        }
                    },
                    "ContentType": "text/csv;label_size=0",
                    "CompressionType": "None",
                    "RecordWrapperType": "None",
                }
            ],
            "OutputDataConfig": {"S3OutputPath": S3_OUTPUT_PATH},
            "ResourceConfig": {
                "InstanceType": "ml.m4.xlarge",
                "InstanceCount": 1,
                "VolumeSizeInGB": 1,
            },
            "StoppingCondition": {"MaxRuntimeInSeconds": 86400},
            "HyperParameters": {
                "eval_metrics": '["accuracy", "precision_recall_fscore"]',
                "feature_dim": "1",
                "num_samples_per_tree": "256",
                "num_trees": "100",
            },
            "EnableManagedSpotTraining": False,
            "EnableNetworkIsolation": False,
            "EnableInterContainerTrafficEncryption": False,
        }


def get_model_key(**context):
    model = context['ti'].xcom_pull(key='JOB_NAME')[0]

    return f'data/{model}/output/model.tar.gz'


# Define DAG
with DAG(
    "sagemaker_training",
    default_args=default_args,
    description="Run a SageMaker training job with DAG run ID",
    schedule_interval=None,  # Can be triggered manually or from another DAG
    catchup=False,
) as dag:
    
    task_train_model = SageMakerTrainingOperator(
        task_id="train_sagemaker_model",
        config=get_training_config(),
        aws_conn_id="aws_default",
        wait_for_completion=True,
    )

  # Step 2: Wait for Model File in S3
    wait_for_model = S3KeySensor(
        task_id="wait_for_model",
        bucket_name="iss-historical-data",
        bucket_key=get_model_key(),
        aws_conn_id="aws_default",
        poke_interval=15,  # Check every 60 seconds
        timeout=600,  # Wait up to 10 mins
    )

    task_train_model >> wait_for_model