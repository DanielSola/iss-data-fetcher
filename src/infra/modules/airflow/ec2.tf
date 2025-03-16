
resource "aws_instance" "airflow" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = "manual"
  security_groups        = [aws_security_group.airflow_sg.name]  # Reference the security group
  iam_instance_profile   = aws_iam_instance_profile.airflow_profile.name  # Reference the IAM instance profile
  
  tags = {
    Name = "airflow"
  }

  user_data = <<-EOF
#!/bin/bash
# Update and install dependencies
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y python3-pip python3-dev libpq-dev libssl-dev libffi-dev build-essential python3-virtualenv unzip pkg-config libxml2-dev libxmlsec1-dev libxmlsec1-openssl

# Create a virtual environment and activate it
cd /home/ubuntu
virtualenv airflow-venv
source airflow-venv/bin/activate

# Install Apache Airflow with the specified version
pip install "apache-airflow==2.10.5" --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-2.10.5/constraints-3.8.txt"
pip install apache-airflow-providers-amazon

# Initialize the Airflow database
airflow db init

# Create an admin user for Airflow
airflow users create \
    --username admin \
    --password admin \
    --firstname FirstName \
    --lastname LastName \
    --email user@example.com \
    --role Admin

# Instal AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Get DAGs from S3 bucket
mkdir -p /home/ubuntu/airflow/dags
aws s3 sync s3://airflow-iss-anomaly-detector/airflow/dag/ /home/ubuntu/airflow/dags/
export AIRFLOW__CORE__DAGS_FOLDER=/home/ubuntu/airflow/dags

# Start the Airflow webserver and scheduler as background processes
nohup airflow webserver --port 8080 &
nohup airflow scheduler &

  EOF

  lifecycle {
    create_before_destroy = true
  }
}