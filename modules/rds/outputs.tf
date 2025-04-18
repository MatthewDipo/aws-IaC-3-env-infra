# Output: RDS Endpoint
# Provides the connection endpoint (hostname) for the created RDS database instance.
# Applications use this endpoint along with the port, username, and password to connect to the database.
output "rds_endpoint" {
  description = "The endpoint of the RDS instance"
  # 'aws_db_instance.postgres.endpoint' refers to the endpoint attribute of the RDS instance resource named 'postgres' in main.tf.
  value = aws_db_instance.main.endpoint
}

# Output: RDS Port
# Provides the network port number on which the RDS database instance is listening for connections.
# Default ports are typically used (e.g., 5432 for PostgreSQL).
output "rds_port" {
  description = "The port of the RDS instance"
  # 'aws_db_instance.postgres.port' refers to the port attribute of the RDS instance resource.
  value = aws_db_instance.main.port
}

# Output: RDS Instance Security Group ID
# Provides the ID of the security group attached directly to the RDS instance.
# This security group controls inbound traffic *to* the database instance (e.g., allowing traffic from the client security group).
output "rds_security_group_id" {
  description = "The ID of the RDS security group"
  # 'aws_security_group.rds.id' refers to the ID of the security group resource named 'rds'.
  value = aws_security_group.rds.id
}

# Output: RDS Client Security Group ID
# Provides the ID of the security group intended for resources (like application servers or EKS pods) that need to connect *to* the RDS instance.
# You would typically allow outbound traffic from resources in this group to the RDS instance security group on the database port.
output "rds_client_security_group_id" {
  description = "The ID of the RDS client security group"
  # 'aws_security_group.rds_client.id' refers to the ID of the security group resource named 'rds_client'.
  value = aws_security_group.rds_client.id
}

# Output: Secrets Manager Secret ARN
# Provides the Amazon Resource Name (ARN) of the secret created in AWS Secrets Manager to store the database credentials.
# ARNs are unique identifiers for AWS resources.
output "secret_arn" {
  description = "ARN of the Secrets Manager secret"
  # 'aws_secretsmanager_secret.rds_credentials.arn' refers to the ARN attribute of the secret resource named 'rds_credentials'.
  value = aws_secretsmanager_secret.rds_credentials.arn
}

# Output: Secrets Manager Secret Name
# Provides the friendly name of the secret created in AWS Secrets Manager.
# Applications can use this name (along with appropriate permissions) to retrieve the database credentials at runtime.
output "secret_name" {
  description = "Name of the Secrets Manager secret"
  # 'aws_secretsmanager_secret.rds_credentials.name' refers to the name attribute of the secret resource.
  value = aws_secretsmanager_secret.rds_credentials.name
}