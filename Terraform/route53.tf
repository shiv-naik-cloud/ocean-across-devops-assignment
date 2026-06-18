# Disabled by default so plan doesn't fail looking up a zone you don't own
data "aws_route53_zone" "main" {
  count = var.enable_dns_and_tls ? 1 : 0

  name = var.domain_name
}

resource "aws_route53_record" "tenant" {
  for_each = var.enable_dns_and_tls ? var.tenants : {}

  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = "${each.key}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}
