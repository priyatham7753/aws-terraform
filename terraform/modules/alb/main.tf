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
    unhealthy_threshold = 5
    timeout             = 10
    interval            = 30
    matcher             = "200"
  }

  tags = { Name = "${var.project_name}-frontend-tg" }
}

resource "aws_lb_listener" "external_http" {
  load_balancer_arn = aws_lb.external.arn
  port              = 80
  protocol          = "HTTP"

  # Forward to frontend — CloudFront connects here over HTTP (http-only origin policy).
  # CloudFront enforces HTTPS at the viewer edge; this leg stays within AWS private network.
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener" "external_https" {
  load_balancer_arn = aws_lb.external.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

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
    unhealthy_threshold = 5
    timeout             = 10
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
    unhealthy_threshold = 5
    timeout             = 10
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
    unhealthy_threshold = 5
    timeout             = 10
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

# Analytics Service Target Group
resource "aws_lb_target_group" "analytics" {
  name     = "${var.project_name}-analytics-tg"
  port     = 3004
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    path                = "/health"
    port                = "3004"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 10
    interval            = 30
    matcher             = "200"
  }

  tags = { Name = "${var.project_name}-analytics-tg" }
}

resource "aws_lb_listener_rule" "analytics" {
  listener_arn = aws_lb_listener.internal_http.arn
  priority     = 40

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.analytics.arn
  }

  condition {
    path_pattern {
      values = ["/api/analytics", "/api/analytics/*"]
    }
  }
}

# AI Assistant Service Target Group
resource "aws_lb_target_group" "ai_assistant" {
  name     = "${var.project_name}-ai-assistant-tg"
  port     = 3005
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    path                = "/health"
    port                = "3005"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 10
    interval            = 30
    matcher             = "200"
  }

  tags = { Name = "${var.project_name}-ai-assistant-tg" }
}

resource "aws_lb_listener_rule" "ai_assistant" {
  listener_arn = aws_lb_listener.internal_http.arn
  priority     = 50

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ai_assistant.arn
  }

  condition {
    path_pattern {
      values = ["/api/assistant", "/api/assistant/*"]
    }
  }
}
