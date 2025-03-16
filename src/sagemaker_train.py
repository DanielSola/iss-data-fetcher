from airflow import DAG
from airflow.providers.amazon.aws.operators.sagemaker import SageMakerTrainingOperator
from airflow.utils.dates import days_ago

# Define SageMaker training parameters
sagemaker_training_config = {
    "TrainingJobName": "isolation-forest-training-job",
    "AlgorithmSpecification": {
        "TrainingImage": "468650794304.dkr.ecr.eu-west-1.amazonaws.com/sklearn-training:0.23-1-cpu-py3",
        "TrainingInputMode": "File",
    },
    "HyperParameters": {
        "n_estimators": "100",
        "contamination": "0.1",
    },
    "RoleArn": "arn:aws:iam::730335312484:role/AirflowExecutionRole",
    "InputDataConfig": [
        {
            "ChannelName": "training",
            "DataSource": {
                "S3DataSource": {
                    "S3Uri": "s3://iss-historical-data/data/loop_A_flowrate.csv",
                    "S3DataType": "S3Prefix",
                    "S3DataDistributionType": "FullyReplicated",
                }
            },
            "ContentType": "text/csv",
        }
    ],
    "OutputDataConfig": {
        "S3OutputPath": "s3://iss-historical-data/output/",
    },
    "ResourceConfig": {
        "InstanceType": "ml.m5.large",
        "InstanceCount": 1,
        "VolumeSizeInGB": 10,
    },
    "StoppingCondition": {
        "MaxRuntimeInSeconds": 3600,
    },
}

# Define the Airflow DAG
with DAG(
    "sagemaker_train_isolation_forest",
    default_args={"owner": "airflow"},
    schedule_interval="@daily",  # Runs daily
    start_date=days_ago(1),
    catchup=False,
) as dag:

    train_model = SageMakerTrainingOperator(
        task_id="train_sagemaker_model",
        config=sagemaker_training_config,
        aws_conn_id="aws_default",  # Uses default AWS connection in Airflow
        wait_for_completion=True,
    )

    train_model
