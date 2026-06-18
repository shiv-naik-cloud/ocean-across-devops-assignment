#!/usr/bin/env bash
# Deploys payroll-app.tar.gz (already built in the calling job) onto one
# tenant's private-subnet EC2 instance via S3 + SSM Run Command - no SSH,
# no public IP, no bastion needed.
set -euo pipefail

TENANT="$1"  # companies | bureaus | employees
PREFIX="$2"  # company | bureau | employee - matches the Terraform tenants map value
BUCKET="$3"

INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=payroll-${TENANT}-ec2" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].InstanceId" --output text)

if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" == "None" ]; then
  echo "No running instance found tagged payroll-${TENANT}-ec2" >&2
  exit 1
fi

aws s3 cp payroll-app.tar.gz "s3://${BUCKET}/${PREFIX}/payroll-app.tar.gz"

COMMAND_ID=$(aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters "{\"commands\":[\"aws s3 cp s3://${BUCKET}/${PREFIX}/payroll-app.tar.gz /home/ec2-user/payroll-app.tar.gz\",\"gunzip -f /home/ec2-user/payroll-app.tar.gz\",\"docker load < /home/ec2-user/payroll-app.tar\",\"docker stop payroll-app || true\",\"docker rm payroll-app || true\",\"docker run -d -p 80:80 --name payroll-app payroll-app\"]}" \
  --query "Command.CommandId" --output text)

aws ssm wait command-executed --command-id "$COMMAND_ID" --instance-id "$INSTANCE_ID" || true

STATUS=$(aws ssm get-command-invocation --command-id "$COMMAND_ID" --instance-id "$INSTANCE_ID" --query "Status" --output text)
echo "Deploy command status: $STATUS"

if [ "$STATUS" != "Success" ]; then
  aws ssm get-command-invocation --command-id "$COMMAND_ID" --instance-id "$INSTANCE_ID"
  exit 1
fi
