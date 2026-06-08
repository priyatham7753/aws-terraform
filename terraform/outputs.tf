# ─── Networking ───────────────────────────────────────────────────────────
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

# ─── Load Balancers ───────────────────────────────────────────────────────
output "external_alb_dns_name" {
  description = "External ALB DNS name (used as CloudFront origin)"
  value       = module.alb.external_alb_dns_name
}

output "internal_alb_dns_name" {
  description = "Internal ALB DNS name (backend routing)"
  value       = module.alb.internal_alb_dns_name
}

# ─── CloudFront ───────────────────────────────────────────────────────────
output "cloudfront_domain_name" {
  description = "CloudFront distribution domain — use this URL to access the application"
  value       = module.cloudfront.cloudfront_domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.cloudfront.cloudfront_distribution_id
}

# ─── DynamoDB ─────────────────────────────────────────────────────────────
output "dynamodb_users_table" {
  description = "DynamoDB Users table name"
  value       = module.dynamodb.users_table_name
}

output "dynamodb_products_table" {
  description = "DynamoDB Products table name"
  value       = module.dynamodb.products_table_name
}

output "dynamodb_orders_table" {
  description = "DynamoDB Orders table name"
  value       = module.dynamodb.orders_table_name
}

# ─── SQS ──────────────────────────────────────────────────────────────────
output "sqs_order_queue_url" {
  description = "SQS order processing queue URL"
  value       = module.sqs.order_queue_url
}

output "sqs_order_dlq_url" {
  description = "SQS order dead letter queue URL"
  value       = module.sqs.order_dlq_url
}

# ─── SNS ──────────────────────────────────────────────────────────────────
output "sns_alerts_topic_arn" {
  description = "SNS alerts topic ARN"
  value       = module.sns.alerts_topic_arn
}

output "sns_orders_topic_arn" {
  description = "SNS orders topic ARN"
  value       = module.sns.orders_topic_arn
}

# ─── Secrets Manager ──────────────────────────────────────────────────────
output "jwt_secret_arn" {
  description = "Secrets Manager JWT secret ARN"
  value       = module.secretsmanager.jwt_secret_arn
}

# ─── S3 ───────────────────────────────────────────────────────────────────
output "product_images_bucket" {
  description = "S3 product images bucket name"
  value       = module.s3.product_images_bucket_name
}

# ─── CloudWatch ───────────────────────────────────────────────────────────
output "cloudwatch_dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = module.cloudwatch.dashboard_name
}
