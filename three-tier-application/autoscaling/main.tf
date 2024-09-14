locals {
  linux_ami = "ami-04a5ce820a419d6da"
}

# web server: load balancer 
resource "aws_lb_target_group" "target_web_server_group" {
  name     = "target-web-server-group"
  port     = 80
  protocol = "HTTP"
  target_type = "instance"
  load_balancing_algorithm_type = "round_robin"
  vpc_id   = var.vpc.id
  deregistration_delay = 300
}

resource "aws_lb" "web_server_alb" {
  name = "web-server-alb"
  load_balancer_type = "application"
  security_groups = [var.load_balancer_sg.id]
  subnets = [for subnet in var.subnets.public : subnet.id]
}

resource "aws_lb_listener" "web_server_alb_listener" {
  load_balancer_arn = aws_lb.web_server_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_web_server_group.arn
  }
}

# web server: auto scaling group
resource "aws_launch_template" "template_web_server" {
    name = "template_web_server"
    instance_type = "t2.micro"
    image_id = local.linux_ami
    vpc_security_group_ids =[ var.web_server_sg.id]
    key_name = var.key_pair_name
    user_data = filebase64("${path.module}/../web_bootstrap.sh")
}

resource "aws_autoscaling_group" "web_server_asg" {
  name = "web_server_asg"
  min_size                  = 1
  max_size                  = 3
  desired_capacity = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"

  vpc_zone_identifier = [for subnet in var.subnets.public : subnet.id]
  target_group_arns = [aws_lb_target_group.target_web_server_group.arn]

  launch_template {
    id = aws_launch_template.template_web_server.id
    version = "$Latest"
  }
}

# backend: load balancer 
resource "aws_lb_target_group" "target_backend_group" {
  name     = "target-backend-group"
  port     = 8080
  protocol = "HTTP"
  target_type = "instance"
  load_balancing_algorithm_type = "round_robin"
  vpc_id   = var.vpc.id
}

resource "aws_lb" "backend_alb" {
  name = "backend-alb"
  load_balancer_type = "application"
  security_groups = [var.backend_sg.id]
  subnets = [for subnet in var.subnets.private : subnet.id]
}

resource "aws_lb_listener" "backend_alb_listener" {
  load_balancer_arn = aws_lb.backend_alb.arn
  port              = "8080"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_backend_group.arn
  }
}

# backend: auto scaling group
resource "aws_launch_template" "template_backend" {
    name = "template_backend"
    instance_type = "t2.micro"
    image_id = local.linux_ami
    vpc_security_group_ids = [var.backend_sg.id]
    key_name = var.key_pair_name
    user_data = filebase64("${path.module}/../backend_bootstrap.sh")

  lifecycle {
      create_before_destroy = true
    }

    # Force update when user data changes
    tag_specifications {
      resource_type = "instance"
      tags = {
        Name = "Backend Instance"
        UserDataHash = filebase64sha256("${path.module}/../backend_bootstrap.sh")
      }
    }
}

resource "aws_autoscaling_group" "backend_asg" {
    name = "backend_asg"
  min_size                  = 1
  max_size                  = 3
  desired_capacity = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"

  vpc_zone_identifier = [for subnet in var.subnets.private : subnet.id]
  target_group_arns = [aws_lb_target_group.target_backend_group.arn]

  launch_template {
    id = aws_launch_template.template_backend.id
    version = "$Latest"
  }
}