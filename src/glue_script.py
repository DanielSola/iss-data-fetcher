import boto3
import os
from datetime import datetime, timedelta
import pytz  # For timezone handling

# AWS S3 client
s3 = boto3.client("s3")

# Specify the bucket name
bucket_name = 'iss-historical-data'

# Calculate the timestamp for 24 hours ago
now = datetime.utcnow().replace(tzinfo=pytz.utc)  # Make it offset-aware (UTC)
time_threshold = now - timedelta(hours=24)

print(f"Listing files modified in the last 24 hours from the bucket: {bucket_name}")

# List the objects in the S3 bucket
response = s3.list_objects_v2(Bucket=bucket_name)

# Check if the bucket has any objects
if 'Contents' in response:
    for obj in response['Contents']:
        # Get the LastModified timestamp of the object
        last_modified = obj['LastModified']

        # Check if the file was modified in the last 24 hours
        if last_modified >= time_threshold:
            print(f"File: {obj['Key']} Last Modified: {last_modified}")
else:
    print("No files found in the specified bucket.")
