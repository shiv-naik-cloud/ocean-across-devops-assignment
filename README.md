*** Task 2 - Multi-Tenancy Architecture ***

*** 2a ***
*Tenant Isolation Strategy*

For this platform, I decided to go with a shared database model with tenant_id based scoping isolation..

I chose this approach because it is more cost-effective & scalable compared to maintaining separate databases or schemas for each tenant.. Since this platform can grow to support many companies, having a separate database per tenant would become expensive & also very difficult to manage.

In this model, every record in the database will have a tenant_id associated with it. This tenant_id represents whether the data belongs to a Company, Buraeu or Employee

At the application level, I'll make sure that every request is tied to a specific tenant. Once a user logs in, their tenant context will be identified (for example, based on their account or token), and all database queries will always include this tenant_id as its filter.

This also ensures that:
1) A Company can only access its own data
2) A Bureau can only access assigned clients
3) An Employee can only see their own payroll data

To make this more secure, I'm also forcing the isolation at the infrastructure level using IAM roles & restricted access to AWS resources, so even if there is a bug in the application, cross-tenant access is still prevented.


*Tenant Context & Request Flow*

Once a user logs in, I assume the system will identify which tenant they belong to..

After login, the system will generate a token (for example, JWT) which contains basic details like user_id & tenant_id. This token will be sent with every request.

For every incoming request, the application will extract the tenant_id from the token & then use it while querying the database.

So, even if multiple tenants share the same DB, each request only returns data that belongs to that specific tenant.

I'm assuming that the tenant context is always enforced at the application layer only, & I'm adding additional security at the infrastructure level using IAM roles & resource-level restrictions.


*Prevent Cross-Tenant Data Leakage*

At the application level, every query is strictly getting filtered using tenant_id.. Lekin, even as a bug or due to any misconfiguration the data could get exposed

So, for that,
1) At the infra level, IAM roles are strictly scoped so that each tenant's compute instance can only access its own S3 data (using prefixes like companies/, bureaus/, employees/)
2) Database access is restricted at the network level using security groups, so only backend services can connect to it


*** 2b ***
*Access Boundaries at Infrastructure Layer*

For strong isolation between tenants, I've enforced access boundaries at the AWS infra level using IAM roles & resource level permissions.

Each tenant type (Companies, Bureaus, Employees) has its own dedicated EC2 instance with a separate IAM role

These IAM roles are tightly scoped & only allow access to specific S3 prefixes like, companies/*, bureaus/* and employees/*

Also, S3 bucket public access is fully blocked, & access is only possible through IAM-authenticated requests


*** 2c ***
*Tenant Onboarding & Offboarding*

When a new tenant is onboarding:
1) A unique tenant_id is generated & stored in the DB
2) All data associated with this tenant is tagged using this tenant_id
3) S3 storage is separated using prefixes
4) Access permissions are automatically enforced through existing IAM roles & policies

For offboarding a tenant:
1) All access for that tenant is revoked
2) Data associated with that tenant is securely deleted from the DB & S3



*** Task 3 - Security & Access Control ***

*** 3a ***
*IAM & Role-Based Access Control*

For this, I've implemented role-based access control using AWS IAM for least-privilege access across all components

Each tenant type has a separate IAM role assigned to its respective EC2 instance using instance profiles

I have avoided using any hardcoded credentials & instead rely on IAM roles attached to EC2 instances for secure access to AWS resources.


*** 3b ***
*Secrets Management*

I've added the DB password using Terraform variables & marked it as sensitive.. However, in a production environment, this would be replaced with a secure secrets management approach.

Secrets would be stored securely in AWS Secrets Manager or Parameter Store, & accessed at runtime by EC2 instances using IAM roles


*** 3c ***
*Encryption*

For data at rest:
1) S3 buckets are configured with versioning & public access is blocked.. 
2) RDS supports encryption at rest, & this can be enabled to ensure that database storage is encrypted.

For data in transit:
1) All communication between services should happen over secure channels (HTTPS/SSL/TLS).
2) Connections to the database should be configured to use SSL to prevent data interception.


*** 3d ***
*Network Security*

The application is deployed inside a VPC with both public & private subnets across multiple AZs

1) Public subnets are used only for components like NAT Gateway to allow controlled outbound internet access.
2) All backend EC2 instances are deployed in private subnets, so they are not directly accessible from the internet.
3) The RDS DB is also placed in private subnets & is not publicly accessible.

Security groups are used to strictly control traffic:
1) EC2 instances only allow limited inbound access (like SSH for admin access)
2) RDS only allows connections from EC2 instances on the required port (PostgreSQL's port 5432)
3) All other traffic is denied by default



*** Task 4 ***
*CI/CD Pipeline*

The pipeline is triggered on every push to the main branch

It performs the following steps:
1) Checks out the latest code
2) Builds a Docker image for the application
3) Saves the image as a tar file
4) Transfers the image to an EC2 instance using SSH
5) Loads & runs the container on the EC2 instance

For handling secrets like SSH key, host name, host IP, I have used GitHub Secrets to avoid exposing credentials in the pipeline configuration.

In a production setup, I would improve this by using AWS Systems Manager instead of SSH



*** Task 5 ***
*Monitoring & Incident Readiness*

To ensure system reliability & quick detection of issues, I'll design a basic monitoring & alerting setup using AWS CloudWatch & SNS

For monitoring:
1) CloudWatch is used to track key metrics such as EC2 CPU utilization & RDS DB connections
2) Log groups can be configured for application & system logs with a defined retention period to avoid unnecessary storage growth

For alerting:
1) CloudWatch alarms can be set for critical thresholds, such as high CPU usage, unusual database activity, etc
2) These alarms trigger notifications using SNS which can notify the team via email


*Incident Response Runbook*

Scenario: DB is accidentally made publicly accessible

Detection:
1) CloudWatch alerts or AWS Config can detect changes in RDS public accessibility settings
2) Unexpected external traffic or connection spikes can also indicate exposure

Investigation:
1) Firstly, will check RDS configuration to confirm if public access is enabled
2) Review security group rules to see if any wide-open access (0.0.0.0/0) is allowed
3) Verify recent changes through AWS CloudTrail logs

Recovery:
1) Immediately disable public access on the RDS instance
2) Restrict security group rules to allow only internal VPC access
3) Rotate DB credentials to prevent misuse
4) Review logs to identify any unauthorized access

Prevention:
1) Enforce infrastructure changes through Terraform only (no manual changes)
2) Use least-privilege IAM policies
3) Enable monitoring & alerts for configuration changes



*** Task 6 ***
*UK Compliance Considerations*

1) Data Protection & GDPR:
I'll make sure that all employee PII & bank details are stored securely.. I'll enforce encryption at rest & in transit, use least-privilege IAM roles, & enable logging to track who accesses sensitive data.. Using S3 versioning & RDS encryption ensures no data is lost & all access is auditable.

2) Data Residency:
I will deploy all resources in AWS regions located in the UK or EU to ensure compliance with data residency requirements. This includes RDS, S3, & all compute resources. I will explicitly block replication or backups outside these regions.

3) Right to Erasure:
If an employee requests data deletion, I'll delete their records from the database & remove any related S3 files (using tenant_id for scoped deletion) I'll also update logs/audit trails to reflect this deletion without exposing sensitive information. This ensures full compliance with GDPR 'right to be forgotten'