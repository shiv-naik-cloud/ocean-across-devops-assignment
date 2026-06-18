# Self-signed default cert so the ALB's HTTPS listener works out of the box,
# without needing an owned domain. Swap in a real cert via acm_certificate_arn
# + enable_dns_and_tls for a deployment with real users (browsers will flag
# this one as untrusted since no CA signed it).
resource "tls_private_key" "alb_self_signed" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "alb" {
  private_key_pem = tls_private_key.alb_self_signed.private_key_pem

  subject {
    common_name  = var.domain_name != "" ? var.domain_name : aws_lb.main.dns_name
    organization = var.project_name
  }

  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "self_signed" {
  private_key      = tls_private_key.alb_self_signed.private_key_pem
  certificate_body = tls_self_signed_cert.alb.cert_pem

  lifecycle {
    create_before_destroy = true
  }
}
