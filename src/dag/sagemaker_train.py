from airflow import DAG
from airflow.providers.amazon.aws.operators.sagemaker import SageMakerTrainingOperator
from airflow.operators.python import PythonOperator
from airflow.providers.amazon.aws.sensors.s3 import S3KeySensor
from datetime import datetime, timedelta
import os
import uuid

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


def generate_job_names(**kwargs):
    """Generate unique SageMaker job names and push to XCom."""
    job_name = f"TRAINING-JOB-{uuid.uuid4().hex[:5]}"
    kwargs['ti'].xcom_push(key="JOB_NAME", value=job_name)


def get_training_config(**kwargs):
    """Retrieve the training job name from XCom and build the SageMaker config."""
    ti = kwargs['ti']
    job_name = ti.xcom_pull(task_ids='generate_job_names', key='JOB_NAME')

    if not job_name:
        raise ValueError("JOB_NAME not found in XCom")

    print(f"Pulled JOB_NAME from XCom: {job_name}")

    return {
        "TrainingJobName": job_name,
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


def get_model_key(**kwargs):
    """Retrieve job name from XCom and construct S3 model path."""
    job_name = kwargs['ti'].xcom_pull(task_ids='generate_job_names', key='JOB_NAME')

    if not job_name:
        raise ValueError("JOB_NAME not found in XCom")

    return f"data/{job_name}/output/model.tar.gz"


# Define DAG
with DAG(
    "sagemaker_training",
    default_args=default_args,
    description="Run a SageMaker training job with dynamically generated job names",
    schedule_interval=None,
    catchup=False,
    render_template_as_native_obj=True
) as dag:
    
    generate_job_names_task = PythonOperator(
        task_id="generate_job_names",
        python_callable=generate_job_names,
        provide_context=True,
    )

    generate_training_config_task = PythonOperator(
        task_id="generate_training_config",
        python_callable=get_training_config,
        provide_context=True,
    )

    task_train_model = SageMakerTrainingOperator(
        task_id="train_sagemaker_model",
        config="{{ ti.xcom_pull(task_ids='generate_training_config', key='return_value') }}",  # ✅ Fixed
        aws_conn_id="aws_default",
        wait_for_completion=True,
    )

    generate_model_key_task = PythonOperator(
        task_id="generate_model_key",
        python_callable=get_model_key,
        provide_context=True,
    )

    wait_for_model = S3KeySensor(
        task_id="wait_for_model",
        bucket_name="iss-historical-data",
        bucket_key="{{ task_instance.xcom_pull(task_ids='generate_model_key', key='return_value') }}",
        aws_conn_id="aws_default",
        poke_interval=15,
        timeout=600,
    )

    # Define task dependencies
    generate_job_names_task >> generate_training_config_task >> task_train_model >> generate_model_key_task >> wait_for_model
