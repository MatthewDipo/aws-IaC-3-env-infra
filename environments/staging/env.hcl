# Define local variables specific to the 'staging' environment.
locals {
  # Set the environment name variable.
  environment = "staging"
  # Set the AWS region for the 'staging' environment.
  region     = "eu-west-2" # London region
}

# Define inputs specific to the 'staging' environment.
# These inputs might be merged by including configurations (like root.hcl),
# but defining them here makes the environment's core settings explicit.
inputs = {
  # Expose the environment name as an input.
  environment = local.environment
  # Expose the AWS region as an input.
  region = local.region
}