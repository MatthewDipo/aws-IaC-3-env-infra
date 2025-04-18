# Define local variables available globally within this root configuration.
locals {
  # Determine the current environment. Defaults to 'dev' if the ENV environment variable is not set.
  env = get_env("ENV", "dev")

  # Automatically load environment-specific variables (like region) from the 'env.hcl' 
  environment_vars = read_terragrunt_config(find_in_parent_folders("live/${local.env}/env.hcl"))

  # Extract common variables from the loaded environment configuration for easier access.
  environment = local.environment_vars.locals.environment # e.g., "dev"
  region      = local.environment_vars.locals.region      # e.g., "eu-west-1"
}

# Configure the remote backend for storing Terraform state files.
remote_state {
  backend = "s3"
  config = {
    # The name of the S3 bucket where state files will be stored.
    bucket         = "tf-state-bucket-mo"
    # The path (key) within the bucket for this specific module's state file.
    key            = "${path_relative_to_include()}/terraform.tfstate"
    # The AWS region where the S3 bucket resides.
    region         = "eu-west-2"
    encrypt        = true
    # The name of the DynamoDB table used for state locking.
    dynamodb_table = "go-app-state-lock"
  }
  # Configuration for automatically generating the backend configuration file.
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Generate the AWS provider configuration file automatically.
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  # The content of the provider configuration file.
  contents  = <<EOF
provider "aws" {
  region = "${local.environment_vars.locals.region}"
}
EOF
}

# Define default inputs that will be merged into the inputs of including Terragrunt configurations.
inputs = merge(
  {
    # Provide the environment name as a default input.
    environment = local.environment
    # Provide the AWS region as a default input.
    region      = local.region
  }
)