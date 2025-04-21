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
  # Use the shared EKS module located at 'modules/eks'.
  source = "../../../modules//eks"
}

# Define dependencies on other infrastructure components.
dependency "vpc" {
  # Specifies that this EKS setup depends on the production VPC defined in the '../vpc' directory.
  config_path = "../vpc"
}

# Define local variables specific to the production EKS cluster.
locals {
  # Read the environment-specific variables (prod, eu-west-3) from 'env.hcl'.
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # --- Production Cluster Configuration ---
  # Define the name for the production EKS cluster (e.g., 'ekscluster-prod').
  cluster_name    = "ekscluster-${local.env_vars.locals.environment}"
  # Specify the Kubernetes version for the production cluster.
  cluster_version = "1.32"

  # --- Production OIDC Provider Configuration ---
  create_oidc_provider = true
  oidc_client_id = "sts.amazonaws.com"

  # --- Production Node Group Configuration ---
  # Define settings for the default node group in production.
  # IMPORTANT: Review and adjust these settings (size, instance type) for production capacity and resilience.
  node_groups = {
    default = {
      min_size      = 1 # Consider a higher minimum for prod resilience
      max_size      = 3 # Adjust max size based on expected prod load
      desired_size  = 2 # Adjust desired size based on expected prod load
      instance_type = "t3.medium" # IMPORTANT: Choose an appropriate instance type for production workload
      capacity_type = "ON_DEMAND" # Consider Spot instances for cost savings where appropriate
      labels = {
        Environment = local.env_vars.locals.environment
        Terraform   = "true"
      }
      taints = [] # Define taints if needed for specific node scheduling in prod
    }
    # Consider adding more node groups for different workloads or instance types in production.
  }

  # --- Production Cluster Logging ---
  # Ensure necessary logs are enabled for production monitoring and auditing.
  cluster_enabled_log_types = ["api", "audit", "authenticator"]
}

# Define the input variables to pass to the shared Terraform EKS module.
inputs = {
  # --- Cluster Settings ---
  cluster_name               = local.cluster_name
  cluster_version           = local.cluster_version
  cluster_enabled_log_types = local.cluster_enabled_log_types

  # --- VPC Configuration --- 
  # Pass the production VPC ID from the dependency.
  vpc_id     = dependency.vpc.outputs.vpc_id
  # Pass the production private subnet IDs from the dependency.
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids

  # --- Environment --- 
  environment = local.env_vars.locals.environment
  region            = local.env_vars.locals.region

  # --- OIDC Provider settings ---
  create_oidc_provider = local.create_oidc_provider
  oidc_client_id      = local.oidc_client_id

  # --- Node groups ---
  node_groups = local.node_groups
} 
