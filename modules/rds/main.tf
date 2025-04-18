# Defines a security group intended for resources (like EC2 instances, Lambda functions, EKS pods)
# that need to connect to the RDS database instance.
resource "aws_security_group" "rds_client" {
  # Name for the security group, including the environment.
  name = "${var.environment}-rds-client-sg"
  # Description of the security group's purpose.
  description = "Security group for RDS clients"
  # The VPC where this security group will be created.
  vpc_id = var.vpc_id

  # Tags for identification and organization.
  tags = merge(var.tags, {
    Name = "${var.environment}-rds-client-sg"
  })
}

locals {
  # Map common engine names to their default ports
  db_ports = {
    postgres      = 5432
    mysql         = 3306
    mariadb       = 3306
    oracle-ee     = 1521
    oracle-se2    = 1521
    oracle-se1    = 1521
    oracle-se     = 1521
    sqlserver-ee  = 1433
    sqlserver-se  = 1433
    sqlserver-ex  = 1433
    sqlserver-web = 1433
  }
  # Determine the port based on the engine variable, defaulting to 0 if not found (should not happen with proper validation)
  db_port = lookup(local.db_ports, var.engine, 0) 
}

# Defines the security group attached directly to the RDS database instance.
# It controls inbound network traffic allowed to reach the database.
resource "aws_security_group" "rds" {
  name        = "${var.environment}-rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = var.vpc_id

  # Ingress Rule: Allows incoming connections.
  ingress {
    # Look up the database port dynamically based on the engine type.
    from_port = local.db_port
    to_port   = local.db_port
    # Protocol allowed (TCP for database connections).
    protocol        = "tcp"
    # Allows traffic *only* from resources associated with the 'rds_client' security group.
    security_groups = [aws_security_group.rds_client.id]
    # A description for the ingress rule.
    description     = "Allow DB connections from client SG on port ${local.db_port}"
  }

  # Egress Rule: Allows all outbound traffic from the RDS instance.
  # This is generally needed for the instance to communicate with AWS services (e.g., for backups, patches).
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # Allow all protocols
    cidr_blocks = ["0.0.0.0/0"] # Allow traffic to any destination
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-rds-sg"
  })
}

# Defines a collection of subnets (typically private) within the VPC where the RDS instance can be placed.
# RDS uses this group to determine which subnets and Availability Zones the instance can operate in.
resource "aws_db_subnet_group" "rds" {
  name        = "${var.environment}-rds-subnet-group"
  description = "RDS subnet group for ${var.environment} environment"
  # List of private subnet IDs provided as input.
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.environment}-rds-subnet-group"
  })
}

# Resource: AWS Secrets Manager Secret
# Creates a secret container in AWS Secrets Manager to store the database credentials.
# Using Secrets Manager is the recommended practice for handling sensitive information like passwords.
resource "aws_secretsmanager_secret" "rds_credentials" {
  # Construct the secret name using the environment and the name provided in variables.
  name = var.secret_name # Using the name directly from the variable now
  # A description for the secret.
  description = "Credentials for ${var.environment} RDS ${var.engine} database"
  # If true, forces overwrite of the secret in replica regions. Usually false unless using multi-region secrets.
  force_overwrite_replica_secret = false
  # Number of days before the secret can be permanently deleted.
  recovery_window_in_days = var.recovery_window_in_days

  tags = merge(var.tags, {
    Name = var.secret_name # Tag with the secret name
  })
}

# Resource: AWS RDS Database Instance
# Defines and creates the actual managed database instance.
resource "aws_db_instance" "main" { # Consider renaming 'postgres' to something generic like 'main' if engine is variable
  # A unique identifier for the RDS instance.
  identifier              = "${var.environment}-${var.engine}" # e.g., "dev-postgres"
  # The database engine type (e.g., "postgres").
  engine                  = var.engine
  # The specific engine version (e.g., "14.7").
  engine_version          = var.engine_version
  # The instance size (e.g., "db.t3.micro").
  instance_class          = var.instance_class
  # The amount of storage allocated (in GiB).
  allocated_storage       = var.allocated_storage

  # The name of the initial database to create.
  db_name                 = var.db_name
  # The master username.
  username                = var.db_username
  
  # Manage the master password with Secrets Manager instead of Terraform state.
  # RDS will generate a password and store it in the secret named by var.secret_name.
  manage_master_user_password = true

  # Attach the RDS security group created earlier.
  vpc_security_group_ids  = [aws_security_group.rds.id]
  # Specify the DB subnet group for network placement.
  db_subnet_group_name    = aws_db_subnet_group.rds.name

  # The number of days to retain automated backups.
  backup_retention_period = var.backup_retention_period
  # Enable Multi-AZ deployment for high availability (only if environment is 'prod').
  multi_az                = var.environment == "prod"
  # Skip creating a final snapshot on deletion for non-prod environments.
  skip_final_snapshot     = var.environment != "prod"
  # Apply necessary tags, merging module defaults with specific tags.
  tags = merge(var.tags, {
    Name = "${var.environment}-${var.engine}-db" # e.g., "dev-postgres-db"
    # Adding more specific component tags
    Component   = "database"
  })

  # Ensure the secret container exists before creating the instance that generates the password for it.
  depends_on = [aws_secretsmanager_secret.rds_credentials]
}
