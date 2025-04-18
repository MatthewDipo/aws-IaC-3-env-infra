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
  # Use the shared VPC module located at 'modules/vpc'.
  source = "../../../modules//vpc"
}

# Define local variables specific to the production VPC.
locals {
  # Read the environment-specific variables (prod, eu-west-3) from 'env.hcl'.
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # --- Production VPC Network Address Configuration ---
  # Define the main IP address range for the production VPC.
  vpc_cidr = "10.0.0.0/16" # Consider if a different CIDR is needed for prod vs non-prod
  
  # Define IP ranges for public subnets in production.
  public_subnet_cidrs = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
  # Define IP ranges for private subnets in production.
  private_subnet_cidrs = [
    "10.0.3.0/24",
    "10.0.4.0/24"
  ]
  # Specify the Availability Zones in the eu-west-3 (Paris) region for production subnets.
  availability_zones = [
    "eu-west-3a",
    "eu-west-3b"
  ]
}

# Define the input variables to pass to the shared Terraform VPC module.
inputs = {
  # Pass the production VPC IP range.
  vpc_cidr             = local.vpc_cidr
  # Pass the list of production public subnet IP ranges.
  public_subnet_cidrs  = local.public_subnet_cidrs
  # Pass the list of production private subnet IP ranges.
  private_subnet_cidrs = local.private_subnet_cidrs
  # Pass the list of production Availability Zones.
  availability_zones   = local.availability_zones
  # Pass the environment name ('prod').
  environment          = local.env_vars.locals.environment
  # Pass the AWS region ('eu-west-3').
  region               = local.env_vars.locals.region
}