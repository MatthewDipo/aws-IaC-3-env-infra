# Include common configurations from the root Terragrunt file.
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Include prod-specific configurations from the 'env.hcl' in the parent directory (live/prod).
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
  # Specifies that this RDS setup depends on the production VPC defined in the '../vpc' directory.
  config_path = "../vpc"
}

# Define local variables specific to the production RDS instance.
locals {
  # Read the environment-specific variables (prod, eu-west-3) from 'env.hcl'.
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  
  # --- Production RDS Instance Configuration ---
  engine                   = "postgres"
  engine_version           = "14.17"
  # IMPORTANT: Choose an appropriate instance class for production workload and resilience.
  instance_class           = "db.t3.micro" # Placeholder - Should likely be larger for production
  # IMPORTANT: Allocate sufficient storage for production data growth.
  allocated_storage        = 20 # Placeholder - Should likely be larger for production
  # IMPORTANT: Set a suitable backup retention period for production data recovery needs (e.g., 7-35 days).
  backup_retention_period  = 7 # Placeholder - Adjust for production requirements
  
  # --- Production Database Credentials and Naming ---
  db_username = "postgres"
  # Define the database name for production (e.g., 'appdb_prod').
  db_name                 = "appdb_${local.env_vars.locals.environment}"
  
  # --- Production Secrets Manager Configuration ---
  # Define the secret name for production (e.g., 'rds-prod-postgres-credentials').
  secret_name             = "rds-${local.env_vars.locals.environment}-postgres-credentials"
  # Set recovery window for production secret (e.g., 30 days to allow recovery).
  recovery_window_in_days = local.env_vars.locals.environment == "prod" ? 30 : 0 # This logic correctly results in 30 for prod
  
  # --- Production Tagging ---
  tags = {
    Environment = local.env_vars.locals.environment
    Terraform   = "true"
    # Add any other production-specific tags (e.g., CostCenter, Owner)
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