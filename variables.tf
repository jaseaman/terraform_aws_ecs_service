variable "environment" {
  type = string
  description = "Environment for the service"
}

variable "name" {
  description = "Name of the service"
  type = string
}

variable "vpc_id" {
  type = string
  description = "The VPC in which the service is to be created under"
}

variable "subnet_ids" {
  type = list(string)
  description = "The subnet ids which the service is to be created under"
}

variable "container_name" {
  type        = string
  description = "The name of the container. Up to 255 characters ([a-z], [A-Z], [0-9], -, _ allowed)"
}

variable "container_image" {
  type        = string
  description = "The image used to start the container. Images in the Docker Hub registry available by default"
}

variable "container_port_mappings" {
  type = list(object({
    containerPort = number
    hostPort      = number
    protocol      = string
  }))

  description = "The port mappings to configure for the container. This is a list of maps. Each map should contain \"containerPort\", \"hostPort\", and \"protocol\", where \"protocol\" is one of \"tcp\" or \"udp\". If using containers in a task with the awsvpc or host network mode, the hostPort can either be left blank or set to the same value as the containerPort"

  default = [
    {
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    }
  ]
}

variable "container_memory" {
  type        = number
  description = "The amount of memory (in MiB) to allow the container to use. This is a hard limit, if the container attempts to exceed the container_memory, the container is killed. This field is optional for Fargate launch type and the total amount of container_memory of all containers in a task will need to be lower than the task memory value"
  default     = 256
}

variable "container_memory_reservation" {
  type        = number
  description = "The amount of memory (in MiB) to reserve for the container. If container needs to exceed this threshold, it can do so up to the set container_memory hard limit"
  default     = 128
}

variable "container_cpu" {
  type        = number
  description = "The number of cpu units to reserve for the container. This is optional for tasks using Fargate launch type and the total amount of container_cpu of all containers in a task will need to be lower than the task-level cpu value"
  default     = 256
}

variable "container_environment_variables" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "The environment variables to pass to the container. This is a list of maps"
  default     = null
}

variable "container_links" {
  type        = list(string)
  description = "List of container names this container can communicate with without port mappings"
  default     = null
}


variable "container_essential" {
  type        = bool
  description = "Determines whether all other containers in a task are stopped, if this container fails or stops for any reason. Due to how Terraform type casts booleans in json it is required to double quote this value"
  default     = true
}

variable "container_healthcheck_path" {
  type = string
  description = "A map containing command (string), timeout, interval (duration in seconds), retries (1-10, number of times to retry before marking container unhealthy), and startPeriod (0-300, optional grace period to wait, in seconds, before failed healthchecks count toward retries)"
  default     = "/api/ping"
}

# https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_LogConfiguration.html
variable "container_log_configuration" {
  type = object({
    logDriver = string
    options   = map(string)
    secretOptions = list(object({
      name      = string
      valueFrom = string
    }))
  })
  description = "Log configuration options to send to a custom log driver for the container. For more details, see https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_LogConfiguration.html"
  default     = null
}

variable "ecs_cluster_arn" {
  type = string
  description = "The arn of the cluster to launch the service on"
}

variable "desired_instances_count" {
  type = number
  description = "The target amount of service containers to scale to"
  default = 1
}

variable "minimum_instances_count" {
  type = number
  description = "The minimum amount of service containers to scale down to"
  default = 1
}

variable "maximum_instances_count" {
  type = number
  description = "The maximum amount of service containers to scale up to"
  default = 2
}

variable "deployment_minimum_healthy_percent" {
  type = number
  description = "The minimum percentage of healthy containers at any time"
  default = 50
}

variable "deployment_maximum_healthy_percent" {
  type = number
  description = "The maximum percentage of healthy containers at any time"
  default = 200
}

variable "alb_listener_arn" {
  type = string
  description = "The arn of the alb listener to apply the listener rule to"
}

variable "alb_security_group_id" {
  type = string
  description = "The security group of the ALB"
  default = ""
}

variable "target_route" {
  type = string
  description = "The route that the ALB listener routes to the service"
}

variable "target_route_priority" {
  type = string
  description = "The priority of the routing, must be unique per load balancer listener "
}
