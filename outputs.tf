output "container_definition" {
  value = module.container_definition
}

output "service_task" {
  value = module.ecs_alb_service_task
}

output "service_autoscaling_target" {
  value = aws_appautoscaling_target.ecs_service_autoscaling
}

output "ecs_service_policy" {
  value = aws_iam_role_policy.ecs_service_policy
}
