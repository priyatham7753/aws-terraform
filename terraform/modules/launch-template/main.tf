# ─── Frontend Launch Template ─────────────────────────────────────────────
resource "aws_launch_template" "frontend" {
  name_prefix   = "${var.project_name}-frontend-"
  image_id      = var.frontend_ami_id
  instance_type = var.frontend_instance_type

  iam_instance_profile {
    name = var.frontend_instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.frontend_sg_id]
  }

  dynamic "key_name" {
    for_each = var.key_pair_name != "" ? [var.key_pair_name] : []
    content {
      # Handled via key_name below
    }
  }

  key_name = var.key_pair_name != "" ? var.key_pair_name : null

  monitoring {
    enabled = true
  }

  user_data = base64encode(templatefile("${path.module}/../../scripts/frontend-userdata.sh", {
    project_name         = var.project_name
    internal_alb_dns     = var.internal_alb_dns_name
    aws_region           = var.aws_region
    ecr_registry         = var.ecr_registry
    docker_image_tag     = var.docker_image_tag
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "${var.project_name}-frontend"
      Role    = "frontend"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ─── Backend Launch Template ──────────────────────────────────────────────
resource "aws_launch_template" "backend" {
  name_prefix   = "${var.project_name}-backend-"
  image_id      = var.backend_ami_id
  instance_type = var.backend_instance_type

  iam_instance_profile {
    name = var.backend_instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.backend_sg_id]
  }

  key_name = var.key_pair_name != "" ? var.key_pair_name : null

  monitoring {
    enabled = true
  }

  user_data = base64encode(templatefile("${path.module}/../../scripts/backend-userdata.sh", {
    project_name              = var.project_name
    aws_region                = var.aws_region
    ecr_registry              = var.ecr_registry
    docker_image_tag          = var.docker_image_tag
    dynamodb_users_table      = "${var.project_name}-users"
    dynamodb_products_table   = "${var.project_name}-products"
    dynamodb_orders_table     = "${var.project_name}-orders"
    sqs_order_queue_url       = var.sqs_order_queue_url
    sns_orders_topic_arn      = var.sns_orders_topic_arn
    sns_alerts_topic_arn      = var.sns_alerts_topic_arn
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-backend"
      Role = "backend"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
