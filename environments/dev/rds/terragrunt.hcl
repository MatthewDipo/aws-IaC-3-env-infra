# Include common configurations from the root Terragrunt file.
# This ensures consistency across different infrastructure components.
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Include environment-specific configurations (like region, environment name)
# from an 'env.hcl' file found in a parent directory.
include "env" {
  path = find_in_parent_folders("env.hcl")
}

# Configure Terraform settings.
terraform {
  # Specify the location of the Terraform module code that defines the RDS infrastructure.
  # The path indicates it's located three levels up in the 'modules/rds' directory.
  source = "../../../modules//rds"
}

# Define dependencies on other infrastructure components.
# This ensures that Terragrunt creates resources in the correct order.
dependency "vpc" {
  # Specifies that this RDS setup depends on the VPC defined in the '../vpc' directory.
  # Terragrunt will apply the VPC configuration first and make its outputs (like subnet IDs) available here.
  config_path = "../vpc"
}

# Define local variables for use within this configuration file.
# These help organize settings and avoid repetition.
locals {
  # Read the environment-specific variables (e.g., 'dev', 'eu-west-1')
  # from the 'env.hcl' file included earlier.
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  
  # --- RDS Instance Configuration ---
  # Specify the database engine type (e.g., postgres, mysql, mariadb, oracle, sqlserver).
  engine                   = "postgres"
  # Specify the version of the database engine.
  engine_version           = "14.17" # Check AWS documentation for supported versions.
  # Specify the compute and memory capacity of the database instance (e.g., db.t3.micro is small).
  instance_class           = "db.t3.micro"
  # The amount of storage to allocate for the database (in GiB).
  allocated_storage        = 20
  # The number of days to retain automated backups.
  backup_retention_period  = 7
  
  # --- Database Credentials and Naming ---
  # The username for the master database user.
  # The actual password will be generated and stored securely by Secrets Manager.
  db_username = "postgres"
  # The name of the initial database to be created within the RDS instance.
  # Includes the environment name for uniqueness (e.g., 'appdb_dev').
  db_name                 = "appdb_${local.env_vars.locals.environment}"
  
  # --- Secrets Manager Configuration ---
  # The name for the secret that will store the generated database credentials in AWS Secrets Manager.
  # Includes the environment name for uniqueness (e.g., 'rds-dev-postgres-credentials').
  secret_name             = "rds-${local.env_vars.locals.environment}-postgres-credentials"
  # The number of days Secrets Manager waits before permanently deleting a secret.
  # Set to 0 for dev (immediate deletion), 30 for prod (allowing recovery).
  recovery_window_in_days = local.env_vars.locals.environment == "prod" ? 30 : 0
  
  # --- Tagging ---
  # Define common tags to apply to the RDS resources.
  tags = {
    Environment = local.env_vars.locals.environment # Tag with the environment name.
    Terraform   = "true"                           # Indicate resource is managed by Terraform.
  }
}

# Define the input variables to pass to the Terraform RDS module specified in the 'source'.
# These inputs customize how the module creates the RDS instance and related resources.
inputs = {
  # --- VPC Configuration ---
  # Pass the VPC ID obtained from the output of the 'vpc' dependency.
  vpc_id             = dependency.vpc.outputs.vpc_id
  # Pass the list of private subnet IDs from the 'vpc' dependency.
  # The RDS instance will be placed within these private subnets for security.
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids
  
  # --- RDS Instance Configuration ---
  # Pass the database engine type defined in locals.
  engine                = local.engine
  # Pass the engine version defined in locals.
  engine_version        = local.engine_version
  # Pass the instance class (size) defined in locals.
  instance_class        = local.instance_class
  # Pass the allocated storage size defined in locals.
  allocated_storage     = local.allocated_storage
  # Pass the backup retention period defined in locals.
  backup_retention_period = local.backup_retention_period
  
  # --- Database Configuration ---
  # Pass the master username defined in locals.
  db_username          = local.db_username 
  # Pass the initial database name defined in locals.
  db_name             = local.db_name
  
  # --- Environment Configuration ---
  # Pass the environment name (e.g., 'dev') from the included env_vars.
  environment         = local.env_vars.locals.environment
  # Pass the AWS region (e.g., 'eu-west-1') from the included env_vars.
  region             = local.env_vars.locals.region
  
  # --- Secrets Manager Configuration ---
  # Pass the desired secret name defined in locals.
  secret_name        = local.secret_name
  # Pass the secret recovery window defined in locals.
  recovery_window_in_days = local.recovery_window_in_days
  
  # --- Tagging ---
  # Pass the map of tags defined in locals.
  tags              = local.tags
}