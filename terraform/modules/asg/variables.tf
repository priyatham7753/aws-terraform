variable "project_name" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "frontend_launch_template_id" { type = string }
variable "frontend_launch_template_version" { type = string }
variable "backend_launch_template_id" { type = string }
variable "backend_launch_template_version" { type = string }
variable "frontend_target_group_arn" { type = string }
variable "auth_target_group_arn" { type = string }
variable "product_target_group_arn" { type = string }
variable "order_target_group_arn" { type = string }
variable "internal_alb_arn_suffix" { type = string; default = "" }
variable "auth_tg_arn_suffix" { type = string; default = "" }
variable "frontend_min_size" { type = number; default = 1 }
variable "frontend_desired_capacity" { type = number; default = 2 }
variable "frontend_max_size" { type = number; default = 4 }
variable "backend_min_size" { type = number; default = 1 }
variable "backend_desired_capacity" { type = number; default = 2 }
variable "backend_max_size" { type = number; default = 4 }
