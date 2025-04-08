from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
import boto3
import json
import csv
import pandas as pd
import pytz

# Define S3 client
s3 = boto3.client("s3")
BUCKET_NAME = "iss-historical-data"
CSV_FILENAME = "loop_A_flowrate.csv"
S3_CSV_PATH = "data/loop_A_flowrate.csv"

# Default arguments for the DAG
default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "start_date": datetime(2024, 3, 16),
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}

def get_data():
    now = datetime.utcnow().replace(tzinfo=pytz.utc)
    yesterday = now - timedelta(hours=24)
    
    response = s3.list_objects_v2(Bucket=BUCKET_NAME)
    if "Contents" not in response:
        return []
    
    files = [obj for obj in response["Contents"] if obj["LastModified"] >= yesterday and obj["Key"].endswith("json")]
    all_data = []
    
    for obj in files:
        key = obj["Key"]
        file_obj = s3.get_object(Bucket=BUCKET_NAME, Key=key)
        file_content = file_obj["Body"].read().decode("utf-8")
        fixed_json = "[" + file_content.replace("}{", "},{") + "]"
        
        try:
            parsed_data = json.loads(fixed_json)
            all_data.extend(parsed_data)
        except json.JSONDecodeError as e:
            print(f"Error parsing {key}: {e}")
    
    return all_data

def process_data():
    data = get_data()
    df = pd.DataFrame(data)
    loop_A_flowrate_data = df[df["name"] == "FLOWRATE"]
    loop_A_flowrate_data = loop_A_flowrate_data[["value"]]
    loop_A_flowrate_data.to_csv(CSV_FILENAME, index=False, header=False)

def upload_to_s3():
    try:
        s3.upload_file(CSV_FILENAME, BUCKET_NAME, S3_CSV_PATH)
        print(f"File {CSV_FILENAME} uploaded successfully to {BUCKET_NAME}/{S3_CSV_PATH}")
    except Exception as e:
        print(f"Error uploading file to S3: {e}")

with DAG(
    "s3_data_processing",
    default_args=default_args,
    description="Extract, transform, and load data from S3",
    schedule_interval=timedelta(minutes=10),
    catchup=False,
    is_paused_upon_creation=True
) as dag:
    
    task_extract = PythonOperator(
        task_id="extract_data",
        python_callable=get_data,
    )
    
    task_transform = PythonOperator(
        task_id="process_data",
        python_callable=process_data,
    )
    
    task_load = PythonOperator(
        task_id="upload_data",
        python_callable=upload_to_s3,
    )

    task_extract >> task_transform >> task_load