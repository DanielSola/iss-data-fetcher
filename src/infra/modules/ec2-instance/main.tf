resource "aws_instance" "iss_data_fetcher" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = var.key_name
  security_groups = ["default"]

  tags = {
    Name = "iss-data-fetcher"
  }

  user_data = <<-EOF
    #!/bin/bash
    yum -y install git nodejs npm
    git clone https://github.com/DanielSola/iss-data-fetcher.git /home/ec2-user/iss-data-fetcher
    cd /home/ec2-user/iss-data-fetcher
    npm i
    npm run start > /home/ec2-user/iss-data-fetcher/app.log 2>&1 &
  EOF

  lifecycle {
    create_before_destroy = true
  }
}

output "instance_ip" {
  value = aws_instance.iss_data_fetcher.public_ip
}
