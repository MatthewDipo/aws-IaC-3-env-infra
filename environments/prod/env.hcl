# Define local variables specific to the 'prod' environment.
locals {
  # Set the environment name variable.
  environment = "prod"
  # Set the AWS region for the 'prod' environment.
  region     = "eu-west-3" # Paris region
}

# Define inputs specific to the 'prod' environment.
# These inputs might be merged by including configurations (like root.hcl),
# but defining them here makes the environment's core settings explicit.
inputs = {
  # Expose the environment name as an input.
  environment = local.environment
  # Expose the AWS region as an input.
  region = local.region
}