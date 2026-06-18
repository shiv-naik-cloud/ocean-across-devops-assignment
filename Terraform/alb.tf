# Terminates TLS, forwards plain HTTP to the tenant EC2 on port 80
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# One target group per tenant
resource "aws_lb_target_group" "tenant" {
  for_each = var.tenants

  name     = "${var.project_name}-${each.key}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }

  tags = {
    Name = "${var.project_name}-${each.key}-tg"
  }
}

resource "aws_lb_target_group_attachment" "tenant" {
  for_each = var.tenants

  target_group_arn = aws_lb_target_group.tenant[each.key].arn
  target_id        = aws_instance.tenant[each.key].id
  port             = 80
}

# Always exists so plan/apply works without an ACM cert; forwards to "companies" by default
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tenant["companies"].arn
  }
}

# Always on - uses the real ACM cert once enable_dns_and_tls + a domain are
# set, otherwise falls back to the self-signed cert in tls.tf
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.enable_dns_and_tls && var.acm_certificate_arn != "" ? var.acm_certificate_arn : aws_acm_certificate.self_signed.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tenant["companies"].arn
  }
}

# bureaus.<domain> / employees.<domain> route to their own target group
resource "aws_lb_listener_rule" "tenant_host_routing" {
  for_each = var.enable_dns_and_tls ? { for k, v in var.tenants : k => v if k != "companies" } : {}

  listener_arn = aws_lb_listener.https.arn
  priority     = 100 + index(keys(var.tenants), each.key)

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tenant[each.key].arn
  }

  condition {
    host_header {
      values = ["${each.key}.${var.domain_name}"]
    }
  }
}
