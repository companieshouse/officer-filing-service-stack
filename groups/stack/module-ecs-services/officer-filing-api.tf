resource "aws_ecs_service" "officer-filing-api-ecs-service" {
  name            = "${var.environment}-${local.service_name}"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.officer-filing-api-task-definition.arn
  desired_count   = 1
  depends_on      = [var.officer-filing-api-lb-arn]
  load_balancer {
    target_group_arn = aws_lb_target_group.officer-filing-api-target_group.arn
    container_port   = var.officer_filing_api_application_port
    container_name   = "eric" # [ALB -> target group -> eric -> officer filing api] so eric container named here
  }
}

resource "aws_ecs_task_definition" "officer-filing-api-task-definition" {
  family                = "${var.environment}-${local.service_name}"
  execution_role_arn    = var.task_execution_role_arn
  container_definitions = templatefile(
    "${path.module}/${local.service_name}-task-definition.tmpl", local.definition
  )
}

resource "aws_lb_target_group" "officer-filing-api-target_group" {
  name     = "${var.environment}-${local.service_name}"
  port     = var.officer_filing_api_application_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    healthy_threshold   = "5"
    unhealthy_threshold = "2"
    interval            = "30"
    matcher             = "200"
    path                = "/officers/healthcheck"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = "5"
  }
}

resource "aws_lb_listener_rule" "officer-filing-api" {
  listener_arn = var.officer-filing-api-lb-listener-arn
  priority     = 1
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.officer-filing-api-target_group.arn
  }
  condition {
    field  = "path-pattern"
    values = ["*"]
  }
}
