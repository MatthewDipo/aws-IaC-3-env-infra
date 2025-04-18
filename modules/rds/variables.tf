# --- Secrets Manager Configuration ---
variable "recovery_window_in_days" {
  description = "Number of days that AWS Secrets Manager waits before it can delete the secret"
  type        = number
}

variable "secret_name" {
  description = "Name of the secret in AWS Secrets Manager"
  type        = string
  default = "rds-postgres-credentials"
}

# --- Environment and Tagging --- 
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
}

# --- Network Configuration ---
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

# --- Database Instance Configuration ---
variable "db_name" {
  description = "Name of the database"
  type        = string
}

variable "db_username" {
  description = "Username for the database"
  type        = string
}

variable "engine" {
  description = "Database engine type"
  type        = string
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
}

variable "instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
}

variable "allocated_storage" {
  description = "The allocated storage in gigabytes"
  type        = number
}

variable "backup_retention_period" {
  description = "The days to retain backups for"
  type        = number
}

# --- (Optional) Database Password Input (Likely Unused with Secrets Manager) ---
# This variable allows passing a password directly. However, the current 'main.tf' likely uses
# AWS Secrets Manager to generate a strong random password, making this variable unnecessary
# unless the module logic is changed to support direct password input.
# Consider removing if not used.
variable "db_password" {
  description = "Password for the master DB user (ignored if using Secrets Manager generation)"
  type        = string
  # 'sensitive = true' prevents Terraform from showing the password in console output.
  sensitive   = true
  # Default to null, assuming Secrets Manager handles password generation.
  default     = null 
}