# Include common configurations from the root Terragrunt file.
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Include staging-specific configurations from the 'env.hcl' in the parent directory (live/staging).
include "env" {
  path = find_in_parent_folders("env.hcl")
}

# Configure Terraform settings.
terraform {
  # Use the shared RDS module located at 'modules/rds'.
  source = "../../../modules//rds"
}

# Define dependencies on other infrastructure components.
dependency "vpc" {
  # Specifies that this RDS setup depends on the staging VPC defined in the '../vpc' directory.
  config_path = "../vpc"
}

# Define local variables specific to the staging RDS instance.
locals {
  # Read the environment-specific variables (staging, eu-west-2) from 'env.hcl'.
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  
  # --- Staging RDS Instance Configuration ---
  engine                   = "postgres"
  engine_version           = "14.17"
  # Use a small instance class suitable for staging.
  instance_class           = "db.t3.micro" 
  # Allocate storage appropriate for staging data.
  allocated_storage        = 20
  # Set backup retention for staging (e.g., 7 days).
  backup_retention_period  = 7
  
  # --- Staging Database Credentials and Naming ---
  db_username = "postgres"
  # Define the database name for staging (e.g., 'appdb_staging').
  db_name                 = "appdb_${local.env_vars.locals.environment}"
  
  # --- Staging Secrets Manager Configuration ---
  # Define the secret name for staging (e.g., 'rds-staging-postgres-credentials').
  secret_name             = "rds-${local.env_vars.locals.environment}-postgres-credentials"
  # Set recovery window for staging (e.g., 0 for immediate deletion or 7 for some recovery).
  recovery_window_in_days = local.env_vars.locals.environment == "prod" ? 30 : 0 # This logic results in 0 for staging
  
  # --- Staging Tagging ---
  tags = {
    Environment = local.env_vars.locals.environment
    Terraform   = "true"
  }
}

# Define the input variables to pass to the shared Terraform RDS module.
inputs = {
  # --- VPC Configuration ---
  vpc_id             = dependency.vpc.outputs.vpc_id
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids
  
  # --- RDS Instance Configuration ---
  engine                = local.engine
  engine_version        = local.engine_version
  instance_class        = local.instance_class
  allocated_storage     = local.allocated_storage
  backup_retention_period = local.backup_retention_period
  
  # --- Database Configuration ---
  db_username          = local.db_username 
  db_name             = local.db_name
  
  # --- Environment Configuration ---
  environment         = local.env_vars.locals.environment
  region             = local.env_vars.locals.region
  
  # --- Secrets Manager Configuration ---
  secret_name        = local.secret_name
  recovery_window_in_days = local.recovery_window_in_days
  
  # --- Tagging ---
  tags              = local.tags
}