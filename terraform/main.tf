locals {
  project_name = var.project_name
  aws_region   = var.aws_region
  environment  = var.environment
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
