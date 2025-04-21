# Include common configurations from the root Terragrunt file.
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Include environment-specific configurations (like region, environment name)
# from an 'env.hcl' file located in a parent directory.
include "env" {
  path = find_in_parent_folders("env.hcl")
}

# Configure Terraform settings.
terraform {
  # Specify the location of the Terraform module code that defines the EKS cluster infrastructure.
  source = "../../../modules//eks"
}

# This ensures that Terragrunt creates resources in the correct order.
dependency "vpc" {
  config_path = "../vpc"
}

# Define local variables for use within this configuration file.
locals {
  # Read the environment-specific variables (like environment name, AWS region)
  # from the 'env.hcl' file included earlier.
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # --- Cluster Configuration ---
  # Define the name for the EKS cluster. It includes the environment name (e.g., 'dev').
  cluster_name    = "ekscluster-${local.env_vars.locals.environment}"
  # Specify the desired version of Kubernetes for the cluster.
  cluster_version = "1.32" # Note: The plan output showed 1.27, this might be overridden or outdated. Consider updating if 1.27 is intended.

  # --- OIDC Provider Configuration (for secure access management within Kubernetes) ---
  # Set to 'true' to create an IAM OpenID Connect (OIDC) provider for the cluster.
  create_oidc_provider = true
  # The audience client ID for the OIDC provider, typically 'sts.amazonaws.com' for AWS IAM.
  oidc_client_id = "sts.amazonaws.com"

  # --- Node Group Configuration (Worker Machines for the Cluster) ---
  # Define the settings for the group(s) of EC2 instances (nodes) that will run containerized applications.
  node_groups = {
    # Configuration for the 'default' node group. You can define multiple groups.
    default = {
      # Minimum number of worker nodes allowed in the group.
      min_size      = 1
      # Maximum number of worker nodes allowed in the group (for scaling).
      max_size      = 3
      # The desired number of worker nodes to start with.
      desired_size  = 2
      # The type of EC2 instance to use for the worker nodes (e.g., t3.medium offers a balance of compute/memory).
      instance_type = "t3.medium"
      # Specifies the pricing model: 'ON_DEMAND' or 'SPOT'.
      capacity_type = "ON_DEMAND"
      # Labels to apply to the Kubernetes nodes, useful for organizing and scheduling workloads.
      labels = {
        Environment = local.env_vars.locals.environment # Label with the environment name.
        Terraform   = "true"                           # Indicate the node was managed by Terraform.
      }
      # Taints to apply to the nodes (not used here). Taints can prevent pods from being scheduled on certain nodes unless they tolerate the taint.
      taints = []
    }
  }

  # --- Cluster Logging Configuration ---
  # Specify which types of logs from the EKS control plane should be sent to AWS CloudWatch Logs.
  # 'api': Logs from the Kubernetes API server.
  # 'audit': Kubernetes audit logs.
  # 'authenticator': Logs related to user authentication.
  cluster_enabled_log_types = ["api", "audit", "authenticator"]
}

# Define the input variables to pass to the Terraform EKS module specified in the 'source'.
inputs = {
  # --- Cluster Settings ---
  # Pass the cluster name defined in locals.
  cluster_name               = local.cluster_name
  # Pass the Kubernetes version defined in locals.
  cluster_version           = local.cluster_version
  # Pass the list of enabled log types defined in locals.
  cluster_enabled_log_types = local.cluster_enabled_log_types

  # --- VPC Configuration ---
  # Pass the VPC ID obtained from the output of the 'vpc' dependency.
  vpc_id     = dependency.vpc.outputs.vpc_id
  # Pass the list of private subnet IDs obtained from the output of the 'vpc' dependency.
  # Worker nodes will be launched in these subnets.
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids

  # --- Environment ---
  # Pass the environment name (e.g., 'dev') from the included env_vars.
  environment = local.env_vars.locals.environment
  # Pass the AWS region (e.g., 'us-east-1') from the included env_vars.
  region            = local.env_vars.locals.region

  # --- OIDC Provider Settings ---
  # Pass the OIDC creation flag defined in locals.
  create_oidc_provider = local.create_oidc_provider
  # Pass the OIDC client ID defined in locals.
  oidc_client_id      = local.oidc_client_id

  # --- Node Groups ---
  # Pass the entire node group configuration map defined in locals.
  node_groups = local.node_groups
}
