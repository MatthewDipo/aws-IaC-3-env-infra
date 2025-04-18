# --- VPC Configuration ---
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

# --- Subnet Configuration ---
variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

# --- Tagging and Identification ---
variable "environment" {
  description = "Environment name"
  type        = string
} 