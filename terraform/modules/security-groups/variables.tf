variable "project_name" { type = string }
variable "vpc_id" { type = string }
variable "ssh_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"] # Restrict in production
}
