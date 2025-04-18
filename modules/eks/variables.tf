# --- General Cluster Configuration ---
variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "The version of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "The environment for the cluster (e.g., dev, staging, prod)"
  type        = string
}

# --- Network Configuration ---
variable "vpc_id" {
  description = "The VPC ID in which to create the EKS cluster"
  type        = string
}

variable "private_subnet_ids" {
  description = "The list of subnet IDs to use for the EKS cluster"
  type        = list(string)
}

# --- Security and Access (IAM OIDC) ---
variable "create_oidc_provider" {
  description = "Whether to create OIDC provider for the cluster"
  type        = bool
}

variable "oidc_client_id" {
  description = "The client ID for the OpenID Connect provider"
  type        = string
}

# --- Logging Configuration ---
variable "cluster_enabled_log_types" {
  description = "A list of the desired control plane logging to enable"
  type        = list(string)
}

# --- Worker Node Configuration ---
variable "node_groups" {
  description = "Map of EKS managed node group configurations"
  type = map(object({
    # Minimum number of nodes in the group.
    min_size = number
    # Maximum number of nodes the group can automatically scale up to.
    max_size = number
    # The initial number of nodes to create in the group.
    desired_size = number
    # The EC2 instance type (e.g., 't3.medium', 'm5.large') determining compute, memory, and network capacity.
    instance_type = string
    # The capacity type: 'ON_DEMAND' for standard pricing or 'SPOT' for potentially cheaper, but interruptible, instances.
    capacity_type = string
    # Kubernetes labels to apply to nodes in this group, useful for targeting pods to specific nodes.
    labels = map(string)
    # Kubernetes taints to apply. Taints repel pods unless they have a matching toleration.
    taints = list(object({
      key    = string # Taint key
      value  = string # Taint value
      effect = string # Taint effect (e.g., 'NoSchedule', 'PreferNoSchedule', 'NoExecute')
    }))
  }))
}