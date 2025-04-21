include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "env" {
  path = find_in_parent_folders("env.hcl")
}

terraform {
  source = "../../../modules//vpc"
}

locals {
  # Get environment variables from the included config
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # VPC configuration
  vpc_cidr = "10.0.0.0/16"
  
  public_subnet_cidrs = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
  private_subnet_cidrs = [
    "10.0.3.0/24",
    "10.0.4.0/24"
  ]
  availability_zones = [
    "eu-west-1a",
    "eu-west-1b"
  ]
}

inputs = {
  vpc_cidr             = local.vpc_cidr
  public_subnet_cidrs  = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs
  availability_zones   = local.availability_zones
  environment          = local.env_vars.locals.environment
  region               = local.env_vars.locals.region
}
