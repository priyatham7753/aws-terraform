variable "project_name" { type = string }
variable "vpc_id" { type = string }
variable "ssh_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
  # Kept for rollback: re-add SSH ingress blocks to frontend/backend SGs and reference this variable
}
