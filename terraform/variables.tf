variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
  default     = "shopmesh"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "prod"
}

# ─── VPC ──────────────────────────────────────────────────────────────────
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs for private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "availability_zones" {
  description = "Availability zones (must match subnet count)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# ─── EC2 ──────────────────────────────────────────────────────────────────
variable "frontend_instance_type" {
  description = "EC2 instance type for frontend ASG"
  type        = string
  default     = "t3.small"
}

variable "backend_instance_type" {
  description = "EC2 instance type for backend ASG"
  type        = string
  default     = "t3.medium"
}

variable "ec2_key_pair_name" {
  description = "EC2 key pair name for SSH access (leave empty to disable)"
  type        = string
  default     = ""
}


# ─── ASG ──────────────────────────────────────────────────────────────────
variable "frontend_asg_min" {
  type    = number
  default = 1
}

variable "frontend_asg_desired" {
  type    = number
  default = 2
}

variable "frontend_asg_max" {
  type    = number
  default = 4
}

variable "backend_asg_min" {
  type    = number
  default = 1
}

variable "backend_asg_desired" {
  type    = number
  default = 2
}

variable "backend_asg_max" {
  type    = number
  default = 4
}

# ─── CloudFront ───────────────────────────────────────────────────────────
variable "cloudfront_price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

# ─── Application ──────────────────────────────────────────────────────────
variable "docker_image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
  default     = "ops@example.com"
}
