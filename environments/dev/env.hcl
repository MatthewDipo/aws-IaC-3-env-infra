# Define local variables specific to the 'dev' environment.
locals {
  # Set the environment name variable.
  environment = "dev"
  # Set the AWS region for the 'dev' environment.
  region     = "eu-west-1"
}

# Define inputs specific to the 'dev' environment.
inputs = {
  # Expose the environment name as an input.
  environment = local.environment
  # Expose the AWS region as an input.
  region = local.region
}