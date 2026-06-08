variable "project_name" {
  type = string
}


variable "frontend_instance_type" {
  type = string
}

variable "backend_instance_type" {
  type = string
}

variable "frontend_sg_id" {
  type = string
}

variable "backend_sg_id" {
  type = string
}

variable "frontend_instance_profile_name" {
  type = string
}

variable "backend_instance_profile_name" {
  type = string
}

variable "key_pair_name" {
  type    = string
  default = ""
}

# Pre-rendered userdata strings (templatefile() called at root level)
variable "frontend_userdata" {
  description = "Rendered frontend userdata script (base64 is applied inside the module)"
  type        = string
}

variable "backend_userdata" {
  description = "Rendered backend userdata script (base64 is applied inside the module)"
  type        = string
}
