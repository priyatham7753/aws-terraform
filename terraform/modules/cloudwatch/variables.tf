variable "project_name" {
  type = string
}

variable "alerts_topic_arn" {
  type = string
}

variable "frontend_asg_name" {
  type = string
}

variable "backend_asg_name" {
  type = string
}

variable "external_alb_arn_suffix" {
  type    = string
  default = ""
}

variable "internal_alb_arn_suffix" {
  type    = string
  default = ""
}

variable "auth_tg_arn_suffix" {
  type    = string
  default = ""
}

variable "sqs_queue_name" {
  type    = string
  default = ""
}
