variable "project_name" {
  type = string
}

variable "external_alb_dns_name" {
  type = string
}

variable "cloudfront_logs_bucket" {
  type = string
}

variable "price_class" {
  type    = string
  default = "PriceClass_100"
}
