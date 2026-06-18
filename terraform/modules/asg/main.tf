# ─── Frontend Auto Scaling Group ──────────────────────────────────────────
resource "aws_autoscaling_group" "frontend" {
  name                      = "${var.project_name}-frontend-asg"
  min_size                  = var.frontend_min_size
  max_size                  = var.frontend_max_size
  desired_capacity          = var.frontend_desired_capacity
  vpc_zone_identifier       = var.public_subnet_ids
  target_group_arns         = [var.frontend_target_group_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = var.frontend_launch_template_id
    version = var.frontend_launch_template_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-frontend"
    propagate_at_launch = true
  }

  tag {
    key                 = "Role"
    value               = "frontend"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Frontend target tracking scaling policy
resource "aws_autoscaling_policy" "frontend_cpu" {
  name                   = "${var.project_name}-frontend-cpu-tracking"
  autoscaling_group_name = aws_autoscaling_group.frontend.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value     = 60.0
    disable_scale_in = false
  }
}

# ─── Backend Auto Scaling Group ───────────────────────────────────────────
resource "aws_autoscaling_group" "backend" {
  name                = "${var.project_name}-backend-asg"
  min_size            = var.backend_min_size
  max_size            = var.backend_max_size
  desired_capacity    = var.backend_desired_capacity
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns = [
    var.auth_target_group_arn,
    var.product_target_group_arn,
    var.order_target_group_arn,
    var.analytics_target_group_arn,
    var.ai_assistant_target_group_arn
  ]
  health_check_type         = "ELB"
  health_check_grace_period = 360

  launch_template {
    id      = var.backend_launch_template_id
    version = var.backend_launch_template_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-backend"
    propagate_at_launch = true
  }

  tag {
    key                 = "Role"
    value               = "backend"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Backend target tracking scaling policy
resource "aws_autoscaling_policy" "backend_cpu" {
  name                   = "${var.project_name}-backend-cpu-tracking"
  autoscaling_group_name = aws_autoscaling_group.backend.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value     = 60.0
    disable_scale_in = false
  }
}

# Backend request count scaling policy (ALB-based)
resource "aws_autoscaling_policy" "backend_requests" {
  name                   = "${var.project_name}-backend-requests-tracking"
  autoscaling_group_name = aws_autoscaling_group.backend.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${var.internal_alb_arn_suffix}/${var.auth_tg_arn_suffix}"
    }
    target_value     = 1000.0
    disable_scale_in = false
  }
}
