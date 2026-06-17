locals {
  project_name = var.project_name
  aws_region   = var.aws_region
  environment  = var.environment
}

# ─── ACM Certificates ─────────────────────────────────────────────────────
# One cert per region:
#   • alb       → default region  (us-east-1)  — attached to ALB HTTPS listener
#   • cloudfront → forced us-east-1             — CloudFront requirement
# Both share the same domain_name so they produce the same DNS validation CNAME.
# Route53 creates that CNAME automatically; no manual DNS work required.

resource "aws_acm_certificate" "alb" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = "${local.project_name}-alb-cert" }
}

resource "aws_acm_certificate" "cloudfront" {
  provider          = aws.us_east_1
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = "${local.project_name}-cloudfront-cert" }
}

# ─── Route53 ──────────────────────────────────────────────────────────────
# Creates:
#   1. Hosted zone for var.domain_name
#   2. ACM CNAME validation records (auto-validates both certs above)
#   3. A alias record: domain_name → CloudFront
#   4. A alias record: www.domain_name → CloudFront
#
# IMPORTANT: After first `terraform apply`, run:
#   terraform output route53_name_servers
# Then update your domain registrar to use these 4 NS records.
# Route53 validation is instant once NS records propagate (minutes–hours).

module "route53" {
  source       = "./modules/route53"
  project_name = local.project_name
  domain_name  = var.domain_name

  # Merge validation options from both certs — duplicate domain_name keys are
  # collapsed in the module's for_each (they produce identical CNAME values).
  # Build a map keyed by domain_name first (deduplicates identical CNAME entries
  # produced by both certs for the same domain), then convert back to a list.
  cert_validation_options = [
    for key, dvos in {
      for dvo in concat(
        [for dvo in aws_acm_certificate.alb.domain_validation_options : {
          domain_name           = dvo.domain_name
          resource_record_name  = dvo.resource_record_name
          resource_record_type  = dvo.resource_record_type
          resource_record_value = dvo.resource_record_value
        }],
        [for dvo in aws_acm_certificate.cloudfront.domain_validation_options : {
          domain_name           = dvo.domain_name
          resource_record_name  = dvo.resource_record_name
          resource_record_type  = dvo.resource_record_type
          resource_record_value = dvo.resource_record_value
        }]
      ) : dvo.domain_name => dvo...
    } : dvos[0]
  ]
}

# Wait for both ACM certs to reach ISSUED state.
# Terraform blocks here until Route53 propagates the validation CNAME
# (typically 1–5 minutes after NS records are in place at the registrar).

resource "aws_acm_certificate_validation" "alb" {
  certificate_arn         = aws_acm_certificate.alb.arn
  validation_record_fqdns = module.route53.acm_validation_record_fqdns

  timeouts {
    create = "15m"
  }
}

resource "aws_acm_certificate_validation" "cloudfront" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = module.route53.acm_validation_record_fqdns

  timeouts {
    create = "15m"
  }
}

# ─── VPC ──────────────────────────────────────────────────────────────────
module "vpc" {
  source               = "./modules/vpc"
  project_name         = local.project_name
  aws_region           = local.aws_region
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

# ─── Security Groups ──────────────────────────────────────────────────────
module "security_groups" {
  source       = "./modules/security-groups"
  project_name = local.project_name
  vpc_id       = module.vpc.vpc_id
}

# ─── IAM ──────────────────────────────────────────────────────────────────
module "iam" {
  source       = "./modules/iam"
  project_name = local.project_name
  aws_region   = local.aws_region
}

# ─── S3 ───────────────────────────────────────────────────────────────────
module "s3" {
  source       = "./modules/s3"
  project_name = local.project_name
}

# ─── DynamoDB ─────────────────────────────────────────────────────────────
module "dynamodb" {
  source       = "./modules/dynamodb"
  project_name = local.project_name
}

# ─── Secrets Manager ──────────────────────────────────────────────────────
module "secretsmanager" {
  source       = "./modules/secretsmanager"
  project_name = local.project_name
  aws_region   = local.aws_region
}

# ─── SNS ──────────────────────────────────────────────────────────────────
module "sns" {
  source       = "./modules/sns"
  project_name = local.project_name
  alert_email  = var.alert_email
}

# ─── SQS ──────────────────────────────────────────────────────────────────
module "sqs" {
  source           = "./modules/sqs"
  project_name     = local.project_name
  backend_role_arn = module.iam.backend_ec2_role_arn
}

# ─── ECR ──────────────────────────────────────────────────────────────────
module "ecr" {
  source       = "./modules/ecr"
  project_name = local.project_name
}

# ─── ALB ──────────────────────────────────────────────────────────────────
module "alb" {
  source             = "./modules/alb"
  project_name       = local.project_name
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  external_alb_sg_id = module.security_groups.external_alb_sg_id
  internal_alb_sg_id = module.security_groups.internal_alb_sg_id
  alb_logs_bucket    = module.s3.alb_logs_bucket_name
  certificate_arn    = aws_acm_certificate_validation.alb.certificate_arn
}

# ─── Launch Templates ─────────────────────────────────────────────────────
# templatefile() is called here (root module) so that the scripts/ path is
# reachable without escaping the module directory boundary.
module "launch_template" {
  source                         = "./modules/launch-template"
  project_name                   = local.project_name
  frontend_instance_type         = var.frontend_instance_type
  backend_instance_type          = var.backend_instance_type
  frontend_sg_id                 = module.security_groups.frontend_sg_id
  backend_sg_id                  = module.security_groups.backend_sg_id
  frontend_instance_profile_name = module.iam.frontend_ec2_instance_profile_name
  backend_instance_profile_name  = module.iam.backend_ec2_instance_profile_name
  key_pair_name                  = var.ec2_key_pair_name

  frontend_userdata = templatefile("${path.module}/scripts/frontend-userdata.sh", {
    project_name     = local.project_name
    internal_alb_dns = module.alb.internal_alb_dns_name
    aws_region       = local.aws_region
    frontend_ecr_url = module.ecr.frontend_repository_url
    docker_image_tag = var.docker_image_tag
  })

  backend_userdata = templatefile("${path.module}/scripts/backend-userdata.sh", {
    project_name             = local.project_name
    aws_region               = local.aws_region
    auth_ecr_url             = module.ecr.auth_repository_url
    product_ecr_url          = module.ecr.product_repository_url
    order_ecr_url            = module.ecr.order_repository_url
    analytics_ecr_url        = module.ecr.analytics_repository_url
    docker_image_tag         = var.docker_image_tag
    dynamodb_users_table     = "${local.project_name}-users"
    dynamodb_products_table  = "${local.project_name}-products"
    dynamodb_orders_table    = "${local.project_name}-orders"
    sqs_order_queue_url      = module.sqs.order_queue_url
    sns_orders_topic_arn     = module.sns.orders_topic_arn
    sns_alerts_topic_arn     = module.sns.alerts_topic_arn
    s3_product_images_bucket = module.s3.product_images_bucket_name
  })


  depends_on = [module.alb, module.sqs, module.sns, module.ecr, module.s3]
}

# ─── Auto Scaling Groups ──────────────────────────────────────────────────
module "asg" {
  source                           = "./modules/asg"
  project_name                     = local.project_name
  public_subnet_ids                = module.vpc.public_subnet_ids
  private_subnet_ids               = module.vpc.private_subnet_ids
  frontend_launch_template_id      = module.launch_template.frontend_launch_template_id
  frontend_launch_template_version = tostring(module.launch_template.frontend_launch_template_version)
  backend_launch_template_id       = module.launch_template.backend_launch_template_id
  backend_launch_template_version  = tostring(module.launch_template.backend_launch_template_version)
  frontend_target_group_arn        = module.alb.frontend_target_group_arn
  auth_target_group_arn            = module.alb.auth_target_group_arn
  product_target_group_arn         = module.alb.product_target_group_arn
  order_target_group_arn           = module.alb.order_target_group_arn
  analytics_target_group_arn       = module.alb.analytics_target_group_arn
  internal_alb_arn_suffix          = module.alb.internal_alb_arn_suffix
  auth_tg_arn_suffix               = module.alb.auth_target_group_arn_suffix
  frontend_min_size                = var.frontend_asg_min
  frontend_desired_capacity        = var.frontend_asg_desired
  frontend_max_size                = var.frontend_asg_max
  backend_min_size                 = var.backend_asg_min
  backend_desired_capacity         = var.backend_asg_desired
  backend_max_size                 = var.backend_asg_max
}

# ─── CloudFront ───────────────────────────────────────────────────────────
module "cloudfront" {
  source                 = "./modules/cloudfront"
  project_name           = local.project_name
  external_alb_dns_name  = module.alb.external_alb_dns_name
  cloudfront_logs_bucket = module.s3.cloudfront_logs_bucket_name
  price_class            = var.cloudfront_price_class
  certificate_arn        = aws_acm_certificate_validation.cloudfront.certificate_arn
  domain_name            = var.domain_name
}

# ─── Route53 A Records (CloudFront alias) ─────────────────────────────────
# Created after both module.route53 (zone) and module.cloudfront (distribution)
# are ready. This avoids the circular dependency that would occur if these
# records lived inside the route53 module.

resource "aws_route53_record" "cloudfront_alias" {
  zone_id = module.route53.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.cloudfront.cloudfront_domain_name
    zone_id                = "Z2FDTNDATAQYW2" # CloudFront hosted zone ID (fixed AWS constant)
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_alias" {
  count   = var.create_www_record ? 1 : 0
  zone_id = module.route53.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = module.cloudfront.cloudfront_domain_name
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

# ─── CloudWatch ───────────────────────────────────────────────────────────
module "cloudwatch" {
  source                  = "./modules/cloudwatch"
  project_name            = local.project_name
  alerts_topic_arn        = module.sns.alerts_topic_arn
  frontend_asg_name       = module.asg.frontend_asg_name
  backend_asg_name        = module.asg.backend_asg_name
  external_alb_arn_suffix = module.alb.external_alb_arn
  internal_alb_arn_suffix = module.alb.internal_alb_arn
  auth_tg_arn_suffix      = module.alb.auth_target_group_arn
  sqs_queue_name          = "${local.project_name}-order-processing"

  depends_on = [module.asg, module.alb, module.sqs]
}

# ─── EventBridge ──────────────────────────────────────────────────────────
module "eventbridge" {
  source               = "./modules/eventbridge"
  project_name         = local.project_name
  orders_topic_arn     = module.sns.orders_topic_arn
  alerts_topic_arn     = module.sns.alerts_topic_arn
  eventbridge_role_arn = module.iam.eventbridge_role_arn
}
