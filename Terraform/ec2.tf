data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }
}

# No SSH key pair - the security group has no inbound SSH rule, so a key
# would be unusable anyway. Admin access goes through SSM Session Manager.
resource "aws_instance" "tenant" {
  for_each = var.tenants

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private[var.tenant_subnet_az_index].id
  vpc_security_group_ids = [aws_security_group.tenant[each.key].id]
  iam_instance_profile   = aws_iam_instance_profile.tenant[each.key].name

  tags = {
    Name = "${var.project_name}-${each.key}-ec2"
  }

  # Ensures the role's policy is attached before the instance boots
  depends_on = [aws_iam_role_policy_attachment.tenant]
}
