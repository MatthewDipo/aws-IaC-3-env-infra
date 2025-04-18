# This main configuration file uses the official Terraform AWS EKS module
# to provision (create and manage) the Elastic Kubernetes Service cluster.
module "eks" {
  # Source: Specifies the location of the reusable module code.
  # Here, it uses the well-known 'terraform-aws-modules/eks/aws' module.
  source = "terraform-aws-modules/eks/aws"
  # Version: Pins the module to a specific compatible version range (~> 20.0 means >= 20.0 and < 21.0).
  # This ensures that future module updates don't break the configuration unexpectedly.
  version = "~> 20.0"

  # --- Basic Cluster Identification ---
  # Pass the cluster name provided via input variable.
  cluster_name = var.cluster_name
  # Pass the Kubernetes version provided via input variable.
  cluster_version = var.cluster_version

  # --- Network Configuration ---
  # Pass the VPC ID provided via input variable.
  vpc_id = var.vpc_id
  # Pass the list of private subnet IDs provided via input variable, where worker nodes will reside.
  subnet_ids = var.private_subnet_ids

  # --- Cluster Access ---
  # Allow public access to the Kubernetes API endpoint. Set to 'false' for private-only access.
  cluster_endpoint_public_access = true

  # --- Worker Nodes ---
  # Pass the node group configurations defined in the input variables.
  # This tells the module how to set up the EC2 instances that will form the cluster's data plane.
  eks_managed_node_groups = var.node_groups

  # --- IAM OIDC Provider / IRSA --- 
  # Enable the IAM OIDC provider and related configurations for IAM Roles for Service Accounts (IRSA).
  # This is controlled by the create_oidc_provider variable passed from Terragrunt.
  enable_irsa = var.create_oidc_provider

  # --- Cluster Add-ons Configuration ---
  # Configure essential Kubernetes components managed by EKS.
  cluster_addons = {
    # CoreDNS: Handles DNS resolution within the cluster (e.g., service discovery).
    coredns = {
      # Use the latest available version of the add-on compatible with the cluster version.
      most_recent = true
      # Custom configuration values for CoreDNS.
      configuration_values = jsonencode({
        computeType  = "EC2" # Specifies CoreDNS pods should run on EC2 nodes (not Fargate).
        replicaCount = 2     # Run two replicas (instances) of CoreDNS for high availability.
      })
      # Timeouts for creating and deleting the add-on.
      timeouts = {
        create = "45m" # Allow up to 45 minutes for creation.
        delete = "30m"
      }
      # Strategy for handling conflicts if the add-on already exists: OVERWRITE will replace it.
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    # Kube Proxy: Maintains network rules on each node, enabling communication between pods and services.
    kube-proxy = {
      most_recent                 = true
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    # VPC CNI: Manages networking for pods, assigning IP addresses from the VPC.
    vpc-cni = {
      most_recent                 = true
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
  }

  # --- Logging ---
  # Pass the list of enabled control plane log types defined in the input variable.
  cluster_enabled_log_types = var.cluster_enabled_log_types

  # --- Tagging ---
  # Apply tags to all resources created by the module for organization and cost tracking.
  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}