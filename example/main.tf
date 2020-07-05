locals {
  environment = "ENVIRONMENT"
  service_name =  "service-name"
  environment_service_name = join("-", [local.environment, local.service_name])
}

provider "aws" {
  region = "us-east-1"
}

module "ecs_service" {
  source = "../"
  container_image = "XXXXXX.dkr.ecr.AWS_REGION.amazonaws.com/NAME:ENVIRONMENT"
  container_name = local.environment_service_name
  ecs_cluster_arn = "arn:aws:ecs:ap-southeast-2:REGION:cluster/CLUSTER_NAME"
  alb_listener_arn = "arn:aws:elasticloadbalancing:AWS_REGION:ACCOUNT:loadbalancer/app/CLUSTER_NAME/XXXXXXX"
  environment = local.environment
  name = local.service_name
  subnet_ids = [
    "subnet-XXXXXXXX",
    "subnet-YYYYYYYY"]
  vpc_id = "vpc-ZZZZZZZ"
  container_port_mappings = [{ containerPort = 8080, hostPort = null, protocol = "tcp"}]
  container_memory = 400
  container_memory_reservation = 200
  target_route = "/api*"
  target_route_priority = 1
  container_healthcheck_path = "/api/health"
  container_log_configuration = {logDriver = "awslogs", options = { awslogs-create-group = "true", awslogs-region = "ap-southeast-2", awslogs-group = local.environment_service_name}, secretOptions = null}

}
