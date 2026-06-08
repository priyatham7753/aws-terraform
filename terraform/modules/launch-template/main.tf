# ─── AMI: Latest Ubuntu 22.04 LTS (Jammy) ────────────────────────────────
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ─── Frontend Launch Template ─────────────────────────────────────────────
resource "aws_launch_template" "frontend" {
  name_prefix   = "${var.project_name}-frontend-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.frontend_instance_type

  iam_instance_profile {
    name = var.frontend_instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.frontend_sg_id]
  }

  key_name = var.key_pair_name != "" ? var.key_pair_name : null

  monitoring {
    enabled = true
  }

  user_data = base64encode(var.frontend_userdata)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-frontend"
      Role = "frontend"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ─── Backend Launch Template ──────────────────────────────────────────────
resource "aws_launch_template" "backend" {
  name_prefix   = "${var.project_name}-backend-"
  image_id      = data.aws_ami.ubuntu.id
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

  user_data = base64encode(var.backend_userdata)

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
