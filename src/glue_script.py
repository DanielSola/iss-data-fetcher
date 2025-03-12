import boto3
import json
import csv
from datetime import datetime, timedelta
import pytz  # For timezone handling
import pandas as pd

# AWS S3 client
s3 = boto3.client("s3")

# Specify the bucket name
bucket_name = 'iss-historical-data'

def get_data():
    now = datetime.utcnow().replace(tzinfo=pytz.utc)  # Make it offset-aware (UTC)
    yesterday = now - timedelta(hours=24)  # Get the correct time range

    print(f"Listing files modified in the last 24 hours from the bucket: {bucket_name}")

    response = s3.list_objects_v2(Bucket=bucket_name)
    
    if 'Contents' not in response:
        print("No files found.")
        return

    files = [obj for obj in response['Contents'] if obj['LastModified'] >= yesterday and obj['Key'].endswith('json')]

    all_data = []

    for obj in files:
        key = obj['Key']
        last_modified = obj['LastModified']
        
        # Fetch the file content
        file_obj = s3.get_object(Bucket=bucket_name, Key=key)
        file_content = file_obj['Body'].read().decode('utf-8')  # Read and decode file content

        # Fix concatenated JSON format
        fixed_json = "[" + file_content.replace("}{", "},{") + "]"

        # Parse JSON
        try:
            parsed_data = json.loads(fixed_json)
            all_data.extend(parsed_data)  # Append parsed data to the list
        except json.JSONDecodeError as e:
            print(f"Error parsing {key}: {e}")
            continue

        #print(f"Processed file: {key}, Last Modified: {last_modified}")

    return all_data

def save_to_csv(data, csv_filename):
    """Writes a list of dictionaries to a CSV file."""
    with open(csv_filename, mode="w", newline="") as file:
        fieldnames = ["timestamp", "value", "name"]
        writer = csv.DictWriter(file, fieldnames=fieldnames)
        
        writer.writeheader()
        writer.writerows(data)

def upload_to_s3(local_filename, bucket_name, s3_filename):
    """Uploads a file to S3."""
    try:
        s3.upload_file(local_filename, bucket_name, s3_filename)
        print(f"File {local_filename} uploaded successfully to {bucket_name}/{s3_filename}")
    except Exception as e:
        print(f"Error uploading file to S3: {e}")

# Run function
data = get_data()

df = pd.DataFrame(data)

print(df)

loop_A_flowrate_data = df[df['name'] == 'Loop A Pump Flowrate (kg/hr)']

csv_filename = "loop_A_flowrate.csv"

save_to_csv(loop_A_flowrate_data.to_dict(orient='records'), csv_filename)

print(f"Data saved to {csv_filename}")

upload_to_s3(csv_filename, bucket_name, "data/loop_A_flowrate.csv")

