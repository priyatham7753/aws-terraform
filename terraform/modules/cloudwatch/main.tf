# ─── CloudWatch Dashboard ─────────────────────────────────────────────────
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0; y = 0; width = 12; height = 6
        properties = {
          title  = "Frontend ASG CPU"
          metrics = [["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "${var.frontend_asg_name}"]]
          period = 300; stat = "Average"; view = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12; y = 0; width = 12; height = 6
        properties = {
          title  = "Backend ASG CPU"
          metrics = [["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "${var.backend_asg_name}"]]
          period = 300; stat = "Average"; view = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0; y = 6; width = 12; height = 6
        properties = {
          title  = "External ALB 5XX Errors"
          metrics = [["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", "${var.external_alb_arn_suffix}"]]
          period = 300; stat = "Sum"; view = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12; y = 6; width = 12; height = 6
        properties = {
          title  = "SQS Order Queue Depth"
          metrics = [["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", "${var.sqs_queue_name}"]]
          period = 60; stat = "Maximum"; view = "timeSeries"
        }
      }
    ]
  })
}

# ─── CPU Alarm — Frontend ─────────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "frontend_cpu_high" {
  alarm_name          = "${var.project_name}-frontend-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Frontend EC2 CPU > 70%"
  alarm_actions       = [var.alerts_topic_arn]
  ok_actions          = [var.alerts_topic_arn]

  dimensions = {
    AutoScalingGroupName = var.frontend_asg_name
  }
}

# ─── CPU Alarm — Backend ──────────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "backend_cpu_high" {
  alarm_name          = "${var.project_name}-backend-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Backend EC2 CPU > 70%"
  alarm_actions       = [var.alerts_topic_arn]
  ok_actions          = [var.alerts_topic_arn]

  dimensions = {
    AutoScalingGroupName = var.backend_asg_name
  }
}

# ─── ALB 5XX Alarm ────────────────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project_name}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "External ALB 5XX errors > 10 in 5 minutes"
  alarm_actions       = [var.alerts_topic_arn]

  dimensions = {
    LoadBalancer = var.external_alb_arn_suffix
  }
}

# ─── Unhealthy Targets Alarm ──────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name          = "${var.project_name}-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "Unhealthy targets detected"
  alarm_actions       = [var.alerts_topic_arn]

  dimensions = {
    LoadBalancer = var.internal_alb_arn_suffix
    TargetGroup  = var.auth_tg_arn_suffix
  }
}

# ─── SQS Queue Depth Alarm ────────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "sqs_queue_depth" {
  alarm_name          = "${var.project_name}-sqs-queue-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Maximum"
  threshold           = 100
  alarm_description   = "SQS order queue depth > 100 messages"
  alarm_actions       = [var.alerts_topic_arn]

  dimensions = {
    QueueName = var.sqs_queue_name
  }
}

# ─── DynamoDB Throttling Alarm ────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "dynamodb_throttles" {
  alarm_name          = "${var.project_name}-dynamodb-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UserErrors"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "DynamoDB user errors (throttling) detected"
  alarm_actions       = [var.alerts_topic_arn]
}

# ─── CloudWatch Log Groups ────────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "auth_service" {
  name              = "/shopmesh/auth-service"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "product_service" {
  name              = "/shopmesh/product-service"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "order_service" {
  name              = "/shopmesh/order-service"
  retention_in_days = 30
}
