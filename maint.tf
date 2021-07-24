locals {
  combined_name = join("-", [
    var.environment,
    var.name])
}

module "container_definition" {
  source = "git::https://github.com/cloudposse/terraform-aws-ecs-container-definition.git?ref=0.49.0"
  container_name = local.combined_name
  container_image = var.container_image
  container_memory = var.container_memory
  container_memory_reservation = var.container_memory_reservation
  container_cpu = var.container_cpu
  essential = var.container_essential
  environment = var.container_environment_variables
  port_mappings = var.container_port_mappings
  log_configuration = var.container_log_configuration
}

module "ecs_alb_service_task" {
  source = "git::https://github.com/cloudposse/terraform-aws-ecs-alb-service-task.git?ref=0.46.1"
  stage = var.environment
  name = var.name
  alb_security_group = var.alb_security_group_id
  container_definition_json = module.container_definition.json_map_encoded_list
  ecs_cluster_arn = var.ecs_cluster_arn
  launch_type = "EC2"
  ecs_load_balancers = [
    {
      container_name = local.combined_name
      container_port = var.container_port_mappings[0].containerPort
      elb_name = null
      target_group_arn = aws_alb_target_group.service_target_group.arn
    }]
  vpc_id = var.vpc_id
  subnet_ids = var.subnet_ids
  tags = {
    Environment = var.environment
  }
  propagate_tags = "SERVICE"
  desired_count = var.minimum_instances_count
  health_check_grace_period_seconds = 20
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent = var.deployment_maximum_healthy_percent
  task_memory = var.container_memory
  task_cpu = var.container_cpu
  network_mode = "bridge"
  ordered_placement_strategy = [
    {
      field = "attribute:ecs.availability-zone",
      type = "spread"
    },
    {
      field = "instanceId",
      type = "spread"
    }]
}

// TODO : Restrict access to only ENVIRONMENT resources
resource "aws_iam_role_policy" "ecs_service_policy" {
  name = "${local.combined_name}-service-policy"
  role = "${local.combined_name}-service"
  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:Describe*",
          "elasticloadbalancing:RegisterInstancesWithLoadBalancer"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
  EOF
  depends_on = [module.ecs_alb_service_task.service_role_arn]
}

resource "aws_alb_target_group" "service_target_group" {
  name = "${local.combined_name}-tg"
  protocol = "HTTP"
  vpc_id = var.vpc_id
  port = var.container_port_mappings[0].containerPort
  deregistration_delay = 20
  target_type = "instance"
  health_check {
    path = var.container_healthcheck_path
    matcher = "200-299"
  }
  tags = {
    environment = var.environment
  }
}

resource "aws_lb_listener_rule" "service_target_group_alb_rule" {
  listener_arn = var.alb_listener_arn
  priority     = var.target_route_priority

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.service_target_group.arn
  }

  condition {
    path_pattern {
      values = [var.target_route]
    }
  }
}

resource "aws_appautoscaling_target" "ecs_service_autoscaling" {
  max_capacity = var.maximum_instances_count
  min_capacity = var.minimum_instances_count
  resource_id = "service/${split("/", var.ecs_cluster_arn)[1]}/${module.ecs_alb_service_task.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace = "ecs"
}
