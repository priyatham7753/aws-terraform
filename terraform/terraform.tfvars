aws_region   = "us-east-1"
project_name = "shopmesh"
environment  = "prod"

vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b"]

frontend_instance_type = "t3.small"
backend_instance_type  = "t3.small"

ec2_key_pair_name = "shopmesh-key"

frontend_asg_min     = 1
frontend_asg_desired = 1
frontend_asg_max     = 1

backend_asg_min     = 1
backend_asg_desired = 1
backend_asg_max     = 1

cloudfront_price_class = "PriceClass_100"

docker_image_tag = "latest"

alert_email = "saidevops753@gmail.com"