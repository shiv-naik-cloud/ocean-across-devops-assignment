# CloudWatch alarms (cloudwatch.tf) publish here, fanning out to email
resource "aws_sns_topic" "critical_alerts" {
  name = "${var.project_name}-critical-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.critical_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
