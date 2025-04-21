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
  # Use the shared EKS module located at 'modules/eks'.
  source = "../../../modules//eks"
}

# Define dependencies on other infrastructure components.
dependency "vpc" {
  # Specifies that this EKS setup depends on the staging VPC defined in the '../vpc' directory.
  config_path = "../vpc"
}

# Define local variables specific to the staging EKS cluster.
locals {
  # Read the environment-specific variables (staging, eu-west-2) from 'env.hcl'.
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # --- Staging Cluster Configuration ---
  # Define the name for the staging EKS cluster (e.g., 'ekscluster-staging').
  cluster_name    = "ekscluster-${local.env_vars.locals.environment}"
  # Specify the Kubernetes version for the staging cluster.
  cluster_version = "1.32"

  # --- Staging OIDC Provider Configuration ---
  create_oidc_provider = true
  oidc_client_id = "sts.amazonaws.com"

  # --- Staging Node Group Configuration ---
  # Define settings for the default node group in staging.
  node_groups = {
    default = {
      min_size      = 1
      max_size      = 3 # Adjust max size based on expected staging load
      desired_size  = 2 # Adjust desired size based on expected staging load
      instance_type = "t3.medium" # Consider instance type based on staging needs
      capacity_type = "ON_DEMAND"
      labels = {
        Environment = local.env_vars.locals.environment
        Terraform   = "true"
      }
      taints = []
    }
  }

  # --- Staging Cluster Logging ---
  cluster_enabled_log_types = ["api", "audit", "authenticator"]
}

# Define the input variables to pass to the shared Terraform EKS module.
inputs = {
  # --- Cluster Settings ---
  cluster_name               = local.cluster_name
  cluster_version           = local.cluster_version
  cluster_enabled_log_types = local.cluster_enabled_log_types

  # --- VPC Configuration --- 
  # Pass the staging VPC ID from the dependency.
  vpc_id     = dependency.vpc.outputs.vpc_id
  # Pass the staging private subnet IDs from the dependency.
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
