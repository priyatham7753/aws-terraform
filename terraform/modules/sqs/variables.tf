variable "project_name" { type = string }
variable "backend_role_arn" { type = string }

variable "additional_role_arns" {
  description = "Extra IAM role ARNs that need SQS access (e.g., IRSA roles)"
  type        = list(string)
  default     = []
}
