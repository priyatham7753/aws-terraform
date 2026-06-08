variable "project_name" { type = string }
variable "aws_region" { type = string }
variable "frontend_ami_id" { type = string }
variable "backend_ami_id" { type = string }
variable "frontend_instance_type" { type = string }
variable "backend_instance_type" { type = string }
variable "frontend_sg_id" { type = string }
variable "backend_sg_id" { type = string }
variable "frontend_instance_profile_name" { type = string }
variable "backend_instance_profile_name" { type = string }
variable "key_pair_name" { type = string; default = "" }
variable "internal_alb_dns_name" { type = string }
variable "ecr_registry" { type = string; default = "" }
variable "docker_image_tag" { type = string; default = "latest" }
variable "sqs_order_queue_url" { type = string; default = "" }
variable "sns_orders_topic_arn" { type = string; default = "" }
variable "sns_alerts_topic_arn" { type = string; default = "" }
