resource "aws_lb" "this" {
  count = var.create ? 1 : 0

  name               = var.name
  internal           = var.internal
  load_balancer_type = "application"
  subnets            = var.subnet_ids
  security_groups    = var.security_group_ids

  lifecycle {
    precondition {
      condition     = length(var.security_group_ids) > 0
      error_message = "At least one security group ID is required for the Application Load Balancer."
    }
  }

  enable_deletion_protection = var.deletion_protection
  idle_timeout               = var.idle_timeout
  enable_http2               = var.enable_http2
  drop_invalid_header_fields = true

  dynamic "access_logs" {
    for_each = var.access_logs_bucket != null ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = var.access_logs_prefix != null ? var.access_logs_prefix : var.name
      enabled = true
    }
  }

  tags = var.tags
}

resource "aws_lb_target_group" "this" {
  for_each = var.create ? var.target_groups : {}

  name_prefix = substr("${var.name}-${each.key}", 0, 24)
  port        = each.value.port
  protocol    = upper(each.value.protocol)
  target_type = each.value.target_type
  vpc_id      = var.vpc_id

  deregistration_delay = each.value.deregistration_delay
  slow_start           = each.value.slow_start

  health_check {
    enabled             = true
    protocol            = upper(coalesce(try(each.value.health_check.protocol, null), each.value.protocol))
    port                = try(each.value.health_check.port, "traffic-port")
    path                = try(each.value.health_check.path, "/")
    matcher             = try(each.value.health_check.matcher, "200-299")
    healthy_threshold   = try(each.value.health_check.healthy_threshold, 3)
    unhealthy_threshold = try(each.value.health_check.unhealthy_threshold, 3)
    interval            = try(each.value.health_check.interval, 30)
    timeout             = try(each.value.health_check.timeout, 5)
  }

  dynamic "stickiness" {
    for_each = each.value.stickiness != null ? [each.value.stickiness] : []
    content {
      type            = stickiness.value.type
      cookie_duration = stickiness.value.cookie_duration
      cookie_name     = stickiness.value.cookie_name
      enabled         = stickiness.value.enabled
    }
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "this" {
  for_each = var.create ? var.listeners : {}

  load_balancer_arn = aws_lb.this[0].arn
  port              = each.value.port
  protocol          = upper(each.value.protocol)
  ssl_policy        = upper(each.value.protocol) == "HTTPS" ? each.value.ssl_policy : null
  certificate_arn   = upper(each.value.protocol) == "HTTPS" ? each.value.certificate_arn : null

  dynamic "default_action" {
    for_each = each.value.redirect != null ? [each.value.redirect] : []
    content {
      type = "redirect"
      redirect {
        port        = default_action.value.port
        protocol    = default_action.value.protocol
        status_code = default_action.value.status_code
      }
    }
  }

  dynamic "default_action" {
    for_each = each.value.redirect == null ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.this[each.value.target_group_key].arn
    }
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = each.value.redirect != null || each.value.target_group_key != null
      error_message = "Listener '${each.key}' must specify either 'redirect' or 'target_group_key'."
    }
    precondition {
      condition     = upper(each.value.protocol) != "HTTPS" || each.value.certificate_arn != null
      error_message = "HTTPS listener '${each.key}' requires 'certificate_arn' to be set."
    }
  }
}

resource "aws_wafv2_web_acl_association" "this" {
  count = var.create && var.associate_waf ? 1 : 0

  resource_arn = aws_lb.this[0].arn
  web_acl_arn  = var.waf_acl_arn

  lifecycle {
    precondition {
      condition     = var.waf_acl_arn != null
      error_message = "waf_acl_arn must be set when associate_waf is true."
    }
  }
}

resource "aws_lb_listener_rule" "this" {
  for_each = var.create ? var.listener_rules : {}

  listener_arn = aws_lb_listener.this[each.value.listener_key].arn
  priority     = each.value.priority

  dynamic "condition" {
    for_each = each.value.path_pattern != null ? [each.value.path_pattern] : []
    content {
      path_pattern {
        values = condition.value
      }
    }
  }

  dynamic "condition" {
    for_each = each.value.host_header != null ? [each.value.host_header] : []
    content {
      host_header {
        values = condition.value
      }
    }
  }

  dynamic "condition" {
    for_each = each.value.http_header != null ? [each.value.http_header] : []
    content {
      http_header {
        http_header_name = condition.value.name
        values           = condition.value.values
      }
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.value.target_group_key].arn
  }

  tags = var.tags
}
