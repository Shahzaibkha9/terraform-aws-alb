module "alb" {
  source = "../.."

  name               = var.name
  internal           = false
  vpc_id             = var.vpc_id
  subnet_ids         = var.subnet_ids
  security_group_ids = var.security_group_ids

  deletion_protection = false

  target_groups = {
    app = {
      port = 8080
    }
  }

  listeners = {
    http = {
      port     = 80
      redirect = { port = "443", protocol = "HTTPS", status_code = "HTTP_301" }
    }
  }
}
