# This block defines the main private network in AWS.
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true

  # Tags to apply to the VPC resource for identification.
  tags = {
    Name        = "${var.environment}-vpc" # e.g., "dev-vpc"
    Environment = var.environment
  }
}

# Creates one or more public subnets based on the provided CIDR blocks and AZs.
resource "aws_subnet" "public" {
  # 'count' creates multiple instances of this resource, one for each item in 'var.public_subnet_cidrs'.
  count = length(var.public_subnet_cidrs)
  # Associate this subnet with the main VPC created above.
  vpc_id = aws_vpc.main.id
  # Assign the specific IP range for this subnet instance using the count index.
  cidr_block = var.public_subnet_cidrs[count.index]
  # Place this subnet in the corresponding Availability Zone using the count index.
  availability_zone = var.availability_zones[count.index]

  # Automatically assign a public IP address to instances launched into this subnet.
  map_public_ip_on_launch = true

  # Tags for the public subnet.
  tags = {
    Name        = "${var.environment}-public-subnet-${count.index + 1}" # e.g., "dev-public-subnet-1"
    Environment = var.environment
    # Kubernetes-specific tag indicating this subnet can be used for public-facing Elastic Load Balancers (ELBs).
    "kubernetes.io/role/elb" = "1"
  }
}

# Creates one or more private subnets based on the provided CIDR blocks and AZs.
resource "aws_subnet" "private" {
  # Creates one private subnet per CIDR block/AZ specified.
  count = length(var.private_subnet_cidrs)
  # Associate with the main VPC.
  vpc_id = aws_vpc.main.id
  # Assign the specific IP range.
  cidr_block = var.private_subnet_cidrs[count.index]
  # Place in the corresponding AZ.
  availability_zone = var.availability_zones[count.index]

  # Tags for the private subnet.
  tags = {
    Name        = "${var.environment}-private-subnet-${count.index + 1}" # e.g., "dev-private-subnet-1"
    Environment = var.environment
    # Kubernetes-specific tag indicating this subnet can be used for internal Elastic Load Balancers (ELBs).
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# Allows communication between the VPC and the internet.
resource "aws_internet_gateway" "main" {
  # Attach the IGW to the main VPC.
  vpc_id = aws_vpc.main.id

  # Tags for the Internet Gateway.
  tags = {
    Name        = "${var.environment}-igw" # e.g., "dev-igw"
    Environment = var.environment
  }
}

# Allocates static public IP addresses, one for each public subnet (to be used by NAT Gateways).
resource "aws_eip" "nat" {
  # Create one EIP per public subnet (matching the count of NAT gateways).
  count = length(var.public_subnet_cidrs)
  # Indicates the EIP is for use within a VPC.
  domain = "vpc"

  # Tags for the Elastic IP.
  tags = {
    Name        = "${var.environment}-nat-eip-${count.index + 1}" # e.g., "dev-nat-eip-1"
    Environment = var.environment
  }
}

# Enables instances in private subnets to connect to the internet or other AWS services,
# but prevents the internet from initiating connections with those instances.
resource "aws_nat_gateway" "main" {
  # Create one NAT Gateway for each public subnet.
  count = length(var.public_subnet_cidrs)
  # Assign the corresponding Elastic IP allocated above.
  allocation_id = aws_eip.nat[count.index].id
  # Place the NAT Gateway in the corresponding public subnet.
  subnet_id = aws_subnet.public[count.index].id

  # Tags for the NAT Gateway.
  tags = {
    Name        = "${var.environment}-nat-${count.index + 1}" # e.g., "dev-nat-1"
    Environment = var.environment
  }
  # Ensure the Internet Gateway is created before the NAT Gateway.
  depends_on = [aws_internet_gateway.main]
}

# Defines routing rules for the public subnets.
resource "aws_route_table" "public" {
  # Associate with the main VPC.
  vpc_id = aws_vpc.main.id

  # Route rule: Direct all internet-bound traffic (0.0.0.0/0) to the Internet Gateway.
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  # Tags for the public route table.
  tags = {
    Name        = "${var.environment}-public-rt" # e.g., "dev-public-rt"
    Environment = var.environment
  }
}

# Defines routing rules for the private subnets.
resource "aws_route_table" "private" {
  # Create one route table per private subnet/NAT gateway.
  count = length(var.private_subnet_cidrs)
  # Associate with the main VPC.
  vpc_id = aws_vpc.main.id

  # Route rule: Direct all internet-bound traffic (0.0.0.0/0) to the corresponding NAT Gateway.
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  # Tags for the private route table.
  tags = {
    Name        = "${var.environment}-private-rt-${count.index + 1}" # e.g., "dev-private-rt-1"
    Environment = var.environment
  }
}

# Associates the public route table with each of the public subnets.
resource "aws_route_table_association" "public" {
  # Create one association per public subnet.
  count = length(var.public_subnet_cidrs)
  # The ID of the public subnet to associate.
  subnet_id = aws_subnet.public[count.index].id
  # The ID of the single public route table.
  route_table_id = aws_route_table.public.id
}

# Associates each private route table with its corresponding private subnet.
resource "aws_route_table_association" "private" {
  # Create one association per private subnet.
  count = length(var.private_subnet_cidrs)
  # The ID of the private subnet to associate.
  subnet_id = aws_subnet.private[count.index].id
  # The ID of the corresponding private route table.
  route_table_id = aws_route_table.private[count.index].id
} 