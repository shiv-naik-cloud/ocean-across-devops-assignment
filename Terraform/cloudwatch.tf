# Per-tenant CPU/status alarms plus a shared RDS alarm, all notifying sns.tf
resource "aws_cloudwatch_log_group" "tenant_app" {
  for_each = var.tenants

  name              = "/${var.project_name}/${each.key}/app"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.payroll.arn
}

resource "aws_cloudwatch_metric_alarm" "tenant_high_cpu" {
  for_each = var.tenants

  alarm_name          = "${var.project_name}-${each.key}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "High CPU on the ${each.key} portal EC2 instance"
  alarm_actions       = [aws_sns_topic.critical_alerts.arn]
  ok_actions          = [aws_sns_topic.critical_alerts.arn]

  dimensions = {
    InstanceId = aws_instance.tenant[each.key].id
  }
}

resource "aws_cloudwatch_metric_alarm" "tenant_status_check_failed" {
  for_each = var.tenants

  alarm_name          = "${var.project_name}-${each.key}-status-check-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "Status check failed on the ${each.key} portal EC2 instance"
  alarm_actions       = [aws_sns_topic.critical_alerts.arn]
  ok_actions          = [aws_sns_topic.critical_alerts.arn]

  dimensions = {
    InstanceId = aws_instance.tenant[each.key].id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_high_connections" {
  alarm_name          = "${var.project_name}-rds-high-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "High connection count on the payroll RDS instance"
  alarm_actions       = [aws_sns_topic.critical_alerts.arn]
  ok_actions          = [aws_sns_topic.critical_alerts.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.id
  }
}
