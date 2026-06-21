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

# !! CHANGE THIS to your real domain before running terraform apply !!
# Route53 hosted zone will be created for this domain.
# After first apply: run `terraform output route53_name_servers` and update
# your domain registrar to use those 4 NS records. ACM validation is automatic
# once the NS records propagate (typically 5–60 minutes).
domain_name       = "shopmesh.shop"
create_www_record = true

# ─── EKS ──────────────────────────────────────────────────────────────────
eks_cluster_version    = "1.30"
eks_node_instance_type = ["t3.medium"]
eks_node_min_size      = 2
eks_node_desired_size  = 2
eks_node_max_size      = 6