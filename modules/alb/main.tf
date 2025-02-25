resource "aws_lb" "alb" {
  name               = "main-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_groups
  subnets            = var.subnets
  tags = {
    Name = "main_alb"
  }
}

resource "aws_lb_target_group" "target_group" {
  name     = "main-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "tg_attachement" {

  # for_each = {
  #   for k, v in var.instances :
  #   k => v
  # }
  for_each = var.instances

  target_group_arn = aws_lb_target_group.target_group.arn
  target_id = var.target_id
  # target_id = each.value.id

  port = 80

}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "autoscaling_attachment_tg" {
  autoscaling_group_name = var.autoscaling_group_name
  lb_target_group_arn    = aws_lb_target_group.target_group.arn
}
