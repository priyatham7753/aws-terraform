data "aws_caller_identity" "current" {}

# ─── Backend EC2 IAM Role ─────────────────────────────────────────────────
resource "aws_iam_role" "backend_ec2" {
  name = "${var.project_name}-backend-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "backend_dynamodb" {
  name = "${var.project_name}-backend-dynamodb"
  role = aws_iam_role.backend_ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:BatchGetItem",
        "dynamodb:BatchWriteItem",
        "dynamodb:DescribeTable"
      ]
      Resource = [
        "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.project_name}-users",
        "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.project_name}-users/index/*",
        "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.project_name}-products",
        "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.project_name}-products/index/*",
        "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.project_name}-orders",
        "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.project_name}-orders/index/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy" "backend_secrets_manager" {
  name = "${var.project_name}-backend-secrets-manager"
  role = aws_iam_role.backend_ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = [
        "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy" "backend_sqs" {
  name = "${var.project_name}-backend-sqs"
  role = aws_iam_role.backend_ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sqs:SendMessage",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl",
        "sqs:ChangeMessageVisibility"
      ]
      Resource = [
        "arn:aws:sqs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.project_name}-*"
      ]
    }]
  })
}

resource "aws_iam_role_policy" "backend_sns" {
  name = "${var.project_name}-backend-sns"
  role = aws_iam_role.backend_ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sns:Publish"]
      Resource = [
        "arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.project_name}-*"
      ]
    }]
  })
}

resource "aws_iam_role_policy" "backend_cloudwatch" {
  name = "${var.project_name}-backend-cloudwatch"
  role = aws_iam_role.backend_ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "cloudwatch:PutMetricData",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy" "backend_ecr" {
  name = "${var.project_name}-backend-ecr"
  role = aws_iam_role.backend_ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "backend_ec2" {
  name = "${var.project_name}-backend-ec2-profile"
  role = aws_iam_role.backend_ec2.name
}

# ─── Frontend EC2 IAM Role ────────────────────────────────────────────────
resource "aws_iam_role" "frontend_ec2" {
  name = "${var.project_name}-frontend-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "frontend_cloudwatch" {
  name = "${var.project_name}-frontend-cloudwatch"
  role = aws_iam_role.frontend_ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "cloudwatch:PutMetricData",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy" "frontend_ecr" {
  name = "${var.project_name}-frontend-ecr"
  role = aws_iam_role.frontend_ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "frontend_ec2" {
  name = "${var.project_name}-frontend-ec2-profile"
  role = aws_iam_role.frontend_ec2.name
}

# ─── EventBridge IAM Role ─────────────────────────────────────────────────
resource "aws_iam_role" "eventbridge" {
  name = "${var.project_name}-eventbridge-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "eventbridge_sns" {
  name = "${var.project_name}-eventbridge-sns"
  role = aws_iam_role.eventbridge.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sns:Publish"]
      Resource = [
        "arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.project_name}-*"
      ]
    }]
  })
}
