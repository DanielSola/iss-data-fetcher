from airflow import DAG
from airflow.providers.amazon.aws.operators.sagemaker import SageMakerTrainingOperator, SageMakerModelOperator, SageMakerEndpointConfigOperator, SageMakerEndpointOperator
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


def generate_job_names(**context):
    job_name = f"TRAINING-JOB-{str(uuid.uuid4())[0:5]}"
    model_name = f"random-cut-forest-model-{str(uuid.uuid4())[0:5]}"
    endpoint_config_name = f"rcf-endpoint-config-{str(uuid.uuid4())[0:5]}"
    endpoint_name = f"rcf-endpoint-{str(uuid.uuid4())[0:5]}"

    context['ti'].xcom_push(key="JOB_NAME", value=job_name)
    context['ti'].xcom_push(key="MODEL_NAME", value=model_name)
    context['ti'].xcom_push(key="ENDPOINT_CONFIG_NAME", value=endpoint_config_name)
    context['ti'].xcom_push(key="ENDPOINT_NAME", value=endpoint_name)

    print(f"Generated JOB_NAME: {job_name}")
    print(f"Generated MODEL_NAME: {model_name}")
    print(f"Generated ENDPOINT_CONFIG_NAME: {endpoint_config_name}")


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

def get_model_config(**context):
    model_name = context["ti"].xcom_pull(task_ids="generate_job_names", key="MODEL_NAME")
    job_name = context["ti"].xcom_pull(task_ids="generate_job_names", key="JOB_NAME")
    
    model_config = {
        "ModelName": model_name,
        "PrimaryContainer": {
            "Image": TRAINING_IMAGE_URI,
            "ModelDataUrl": f"s3://iss-historical-data/data/{job_name}/output/model.tar.gz",
        },
        "ExecutionRoleArn": SAGEMAKER_ROLE_ARN,
    }
    
    context["ti"].xcom_push(key="model_config", value=model_config)

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

    generate_model_config_task = PythonOperator(
        task_id="generate_model_config",
        python_callable=get_model_config,
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

    register_model = SageMakerModelOperator(
        task_id="register_model",
        config="{{ ti.xcom_pull(task_ids='generate_model_config', key='model_config') }}",
        aws_conn_id="aws_default",
    )

   # Step 4: Create a New Endpoint Configuration
    create_endpoint_config = SageMakerEndpointConfigOperator(
        task_id="create_endpoint_config",
        config={
            "EndpointConfigName": "{{ ti.xcom_pull(task_ids='generate_job_names', key='ENDPOINT_CONFIG_NAME') }}",
            "ProductionVariants": [
                {
                    "VariantName": "AllTraffic",
                    "ModelName": "{{ ti.xcom_pull(task_ids='generate_job_names', key='MODEL_NAME') }}",
                    "InitialInstanceCount": 1,
                    "InstanceType": "ml.m4.xlarge",
                }
            ],
        },
        aws_conn_id="aws_default",
    )

    """
    # Step 5: Delete Existing Endpoint (if it exists)
    def delete_existing_endpoint():
        hook = SageMakerHook(aws_conn_id="aws_default")
        existing_endpoints = hook.list_endpoints()
        if ENDPOINT_NAME in existing_endpoints:
            print(f"Deleting existing endpoint: {ENDPOINT_NAME}")
            hook.delete_endpoint(endpoint_name=ENDPOINT_NAME)

    delete_endpoint_if_exists = PythonOperator(
        task_id="delete_old_endpoint",
        python_callable=delete_existing_endpoint,
    )

    """

    # Step 6: Deploy the Model
    deploy_model = SageMakerEndpointOperator(
        task_id="deploy_model",
        config={
            "EndpointName":  "{{ ti.xcom_pull(task_ids='generate_job_names', key='ENDPOINT_NAME') }}",
            "EndpointConfigName": "{{ ti.xcom_pull(task_ids='generate_job_names', key='ENDPOINT_CONFIG_NAME') }}",
        },
        aws_conn_id="aws_default",
    )
    
    # Define task dependencies
    generate_job_names_task >> generate_training_config_task >> task_train_model >> generate_model_key_task >> wait_for_model >> generate_model_config_task >> register_model >> create_endpoint_config >> deploy_model
