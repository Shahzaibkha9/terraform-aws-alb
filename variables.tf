variable "create" {
  description = "Controls whether the ALB and associated resources are created."
  type        = bool
  default     = true
}

variable "name" {
  description = "Name of the ALB. Also used as a prefix for target group names."
  type        = string
  nullable    = false
}

variable "internal" {
  description = "Set to true for an internal ALB, false for internet-facing."
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID where target groups will be created."
  type        = string
  nullable    = false
}

variable "subnet_ids" {
  description = "List of subnet IDs. Use public subnets for internet-facing, private for internal."
  type        = list(string)
  nullable    = false
}

variable "security_group_ids" {
  description = "List of security group IDs to assign to the ALB."
  type        = list(string)
  default     = []
}

variable "deletion_protection" {
  description = "If true, the ALB cannot be deleted via the AWS API."
  type        = bool
  default     = false
}

variable "idle_timeout" {
  description = "Connection idle timeout in seconds."
  type        = number
  default     = 60
}

variable "enable_http2" {
  description = "Whether HTTP/2 is enabled."
  type        = bool
  default     = true
}

variable "access_logs_bucket" {
  description = "S3 bucket name for ALB access logs. Set to null to disable."
  type        = string
  default     = null
}

variable "access_logs_prefix" {
  description = "S3 key prefix for access logs. Defaults to the ALB name when null."
  type        = string
  default     = null
}

variable "target_groups" {
  description = <<-EOT
    Map of target groups to create. Key is a logical name referenced by listeners and rules.

    Example:
      target_groups = {
        app = {
          port     = 8080
          protocol = "HTTP"
          health_check = {
            path    = "/health"
            matcher = "200"
          }
        }
      }
  EOT
  type = map(object({
    port                 = number
    protocol             = optional(string, "HTTP")
    target_type          = optional(string, "ip")
    deregistration_delay = optional(number, 30)
    slow_start           = optional(number, 0)
    health_check = optional(object({
      protocol            = optional(string, "HTTP")
      port                = optional(string, "traffic-port")
      path                = optional(string, "/")
      matcher             = optional(string, "200-299")
      healthy_threshold   = optional(number, 3)
      unhealthy_threshold = optional(number, 3)
      interval            = optional(number, 30)
      timeout             = optional(number, 5)
    }), null)
    stickiness = optional(object({
      type            = optional(string, "lb_cookie")
      cookie_duration = optional(number, 86400)
      cookie_name     = optional(string, null)
      enabled         = optional(bool, true)
    }), null)
  }))
  default = {}
}

variable "listeners" {
  description = <<-EOT
    Map of listeners to create. Key is a logical name (e.g. "http", "https").

    Example:
      listeners = {
        http = {
          port     = 80
          redirect = { port = "443", protocol = "HTTPS", status_code = "HTTP_301" }
        }
        https = {
          port             = 443
          protocol         = "HTTPS"
          certificate_arn  = module.acm.arn
          target_group_key = "app"
        }
      }
  EOT
  type = map(object({
    port             = number
    protocol         = optional(string, "HTTP")
    target_group_key = optional(string, null)
    certificate_arn  = optional(string, null)
    ssl_policy       = optional(string, "ELBSecurityPolicy-TLS13-1-2-2021-06")
    redirect = optional(object({
      port        = optional(string, "443")
      protocol    = optional(string, "HTTPS")
      status_code = optional(string, "HTTP_301")
    }), null)
  }))
  default = {}
}

variable "listener_rules" {
  description = <<-EOT
    Map of listener rules for path- and host-based routing. Key is a logical name.

    Example:
      listener_rules = {
        api = {
          listener_key     = "https"
          target_group_key = "api"
          priority         = 10
          path_pattern     = ["/api/*"]
        }
      }
  EOT
  type = map(object({
    listener_key     = string
    target_group_key = string
    priority         = optional(number, null)
    path_pattern     = optional(list(string), null)
    host_header      = optional(list(string), null)
    http_header = optional(object({
      name   = string
      values = list(string)
    }), null)
  }))
  default = {}
}

variable "waf_acl_arn" {
  description = "ARN of a WAFv2 web ACL to associate with the ALB. Recommended for internet-facing ALBs."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
