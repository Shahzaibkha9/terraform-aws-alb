module "alb" {
  source = "../.."

  name               = var.name
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
      port             = 80
      target_group_key = "app"
    }
  }
}
