# terraform-aws-alb

<img width="600" alt="SUDO x AWS" src="https://github.com/user-attachments/assets/f7044ff9-afce-4811-91c6-2f3c95635abb" />

A Terraform module for AWS Application Load Balancer (ALB). Creates and manages ALBs, target groups, HTTP/HTTPS listeners, and listener rules with path- and host-based routing. Designed for ECS Fargate services using IP-based target groups.

## Usage

### Minimal

```hcl
module "alb" {
  source = "sudo-terraform-aws-modules/alb/aws"

  name               = "my-app"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnets
  security_group_ids = [aws_security_group.alb.id]

  target_groups = {
    app = { port = 8080 }
  }

  listeners = {
    http = { port = 80, target_group_key = "app" }
  }
}
```

### Complete (HTTPS + redirect + path routing)

```hcl
module "alb" {
  source = "sudo-terraform-aws-modules/alb/aws"

  name               = "my-app"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnets
  security_group_ids = [aws_security_group.alb.id]

  target_groups = {
    app = {
      port     = 8080
      health_check = { path = "/health", matcher = "200" }
    }
    api = {
      port     = 9090
      health_check = { path = "/api/health", matcher = "200-299" }
    }
  }

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

  listener_rules = {
    api = {
      listener_key     = "https"
      target_group_key = "api"
      priority         = 10
      path_pattern     = ["/api/*"]
    }
  }

  tags = { Environment = "production" }
}
```

### Route53 alias record

```hcl
module "route53" {
  source    = "sudo-terraform-aws-modules/sudo-route53/aws"
  zone_id   = data.aws_route53_zone.this.zone_id
  zone_name = "example.com"

  records = [
    {
      name  = "app"
      type  = "A"
      alias = {
        name                   = module.alb.dns_name
        zone_id                = module.alb.zone_id
        evaluate_target_health = true
      }
    }
  ]
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3.0 |
| aws | >= 6.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name of the ALB. | `string` | n/a | yes |
| vpc\_id | VPC ID where target groups will be created. | `string` | n/a | yes |
| subnet\_ids | List of subnet IDs. | `list(string)` | n/a | yes |
| security\_group\_ids | List of security group IDs. | `list(string)` | `[]` | no |
| create | Controls whether the ALB and resources are created. | `bool` | `true` | no |
| internal | Set to true for an internal ALB. | `bool` | `false` | no |
| deletion\_protection | If true, the ALB cannot be deleted via the API. | `bool` | `false` | no |
| idle\_timeout | Connection idle timeout in seconds. | `number` | `60` | no |
| enable\_http2 | Whether HTTP/2 is enabled. | `bool` | `true` | no |
| access\_logs\_bucket | S3 bucket for access logs. Null disables logging. | `string` | `null` | no |
| access\_logs\_prefix | S3 key prefix for access logs. | `string` | `null` | no |
| target\_groups | Map of target groups to create. | `map(object(...))` | `{}` | no |
| listeners | Map of listeners to create. | `map(object(...))` | `{}` | no |
| listener\_rules | Map of listener rules for path/host routing. | `map(object(...))` | `{}` | no |
| tags | Tags to apply to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| arn | ARN of the ALB. |
| dns\_name | DNS name of the ALB. Use as the Route53 alias target. |
| zone\_id | Hosted zone ID. Use with Route53 alias records. |
| id | ID of the ALB. |
| target\_group\_arns | Map of logical key to target group ARN. |
| target\_groups | Map of target group attributes. |
| listener\_arns | Map of logical key to listener ARN. |
| listener\_rule\_arns | Map of logical key to listener rule ARN. |
<!-- END_TF_DOCS -->
