resource "aws_security_group" "airflow_sg" {
  name_prefix = "airflow-sg-"
  description = "Security group for Airflow instance"
  
  # Allow HTTP access to Airflow web UI (port 8080)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow access from any IP (change to a specific IP if required)
  }
  
  # Allow SSH access (port 22) from specific IP for remote access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Open to all IPs (for testing; restrict it in production)
  }

  # Allow outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}