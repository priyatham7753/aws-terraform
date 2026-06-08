# ─── External ALB (public, facing internet) ───────────────────────────────
resource "aws_lb" "external" {
  name               = "${var.project_name}-external-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.external_alb_sg_id]
  subnets            = var.public_subnet_ids

  access_logs {
    bucket  = var.alb_logs_bucket
    prefix  = "external-alb"
    enabled = true
  }

  tags = { Name = "${var.project_name}-external-alb" }
}

resource "aws_lb_target_group" "frontend" {
  name     = "${var.project_name}-frontend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = { Name = "${var.project_name}-frontend-tg" }
}

resource "aws_lb_listener" "external_http" {
  load_balancer_arn = aws_lb.external.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# ─── Internal ALB (private, backend traffic) ──────────────────────────────
resource "aws_lb" "internal" {
  name               = "${var.project_name}-internal-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.internal_alb_sg_id]
  subnets            = var.private_subnet_ids

  access_logs {
    bucket  = var.alb_logs_bucket
    prefix  = "internal-alb"
    enabled = true
  }

  tags = { Name = "${var.project_name}-internal-alb" }
}

# Auth Service Target Group
resource "aws_lb_target_group" "auth" {
  name     = "${var.project_name}-auth-tg"
  port     = 3001
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    path                = "/health"
    port                = "3001"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = { Name = "${var.project_name}-auth-tg" }
}

# Product Service Target Group
resource "aws_lb_target_group" "product" {
  name     = "${var.project_name}-product-tg"
  port     = 3002
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    path                = "/health"
    port                = "3002"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = { Name = "${var.project_name}-product-tg" }
}

# Order Service Target Group
resource "aws_lb_target_group" "order" {
  name     = "${var.project_name}-order-tg"
  port     = 3003
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    path                = "/health"
    port                = "3003"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = { Name = "${var.project_name}-order-tg" }
}

resource "aws_lb_listener" "internal_http" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 80
  protocol          = "HTTP"

  # Default: 404 (no default path)
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "application/json"
      message_body = "{\"error\":\"Route not found\"}"
      status_code  = "404"
    }
  }
}

# Listener rules for path-based routing
resource "aws_lb_listener_rule" "auth" {
  listener_arn = aws_lb_listener.internal_http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.auth.arn
  }

  condition {
    path_pattern {
      values = ["/api/auth/*"]
    }
  }
}

resource "aws_lb_listener_rule" "product" {
  listener_arn = aws_lb_listener.internal_http.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.product.arn
  }

  condition {
    path_pattern {
      values = ["/api/products/*"]
    }
  }
}

resource "aws_lb_listener_rule" "order" {
  listener_arn = aws_lb_listener.internal_http.arn
  priority     = 30

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.order.arn
  }

  condition {
    path_pattern {
      values = ["/api/orders/*"]
    }
  }
}
