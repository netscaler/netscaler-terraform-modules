
#### Networking ####
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "${var.deploy_prefix}-VPC"
  }
}

locals {
  distinct_azs = distinct([for sn in var.public_subnets : sn.az])
}

resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id            = aws_vpc.this.id
  availability_zone = var.public_subnets[count.index].az
  cidr_block        = var.public_subnets[count.index].cidr
  # map_public_ip_on_launch = true

  tags = {
    Name = "${var.deploy_prefix}-PublicSubnet-${count.index}"
  }
}

resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id            = aws_vpc.this.id
  availability_zone = var.private_subnets[count.index].az
  cidr_block        = var.private_subnets[count.index].cidr
  # map_public_ip_on_launch = true

  tags = {
    Name = "${var.deploy_prefix}-PrivateSubnet-${count.index}"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.deploy_prefix}-InternetGateway"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.deploy_prefix}-PublicRouteTable"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public[count.index].id
}

resource "aws_route_table" "private" {
  count  = length(aws_subnet.private)
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.deploy_prefix}-PrivateRouteTable-${count.index}"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  route_table_id = aws_route_table.private[count.index].id
  subnet_id      = aws_subnet.private[count.index].id
}

# create EIPs equal to the number of availability zones containing Public Subnets. Each EIP will be associated with a NATGateway
resource "aws_eip" "natgw" {
  count = var.create_nat_gateways && length(var.private_subnets) > 0 ? length(var.public_subnets) : 0

  vpc = true

  tags = {
    Name = "${var.deploy_prefix}-NATGateway-${count.index}"
  }
}

# create NAT gateways equal to the number of availability zones containing Public Subnets
resource "aws_nat_gateway" "this" {
  count = var.create_nat_gateways && length(var.public_subnets) > 0 ? length(var.public_subnets) : 0

  subnet_id     = aws_subnet.public[count.index].id
  allocation_id = aws_eip.natgw[count.index].id

  tags = {
    Name = "${var.deploy_prefix}-PublicSubnet-${count.index}"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.this]
}

# create a route to the NAT gateway for each public subnet
resource "aws_route" "natgw" {
  count = var.create_nat_gateways && length(var.private_subnets) > 0 ? length(var.public_subnets) : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index].id
}
