# =========| VPC |======================
data "aws_availability_zones" "available" {}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc-cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "${var.environment}-vpc"
  }
}
# ======================================


# =========| INTERNET GATEWAY |=========
resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Demo-${var.env}-${var.app}"
  }
}
# ======================================


# =========| EIP |======================
resource "aws_eip" "eip-for-nat-gateway" {
  vpc    = true
  count = length(var.eip)
  tags   = {
    Name = "${var.eip[count.index]}"
  }
}
# ======================================


# =========| NAT GATEWAYS |=============
resource "aws_nat_gateway" "nat-gateway" {
  count = 2
  allocation_id = element(aws_eip.eip-for-nat-gateway.*.id, count.index)
  subnet_id     = element(aws_subnet.public-subnet.*.id, count.index)

  tags = {
    Name = "NAT Gateway Public Subnet ${count.index}"
  }
}
# ======================================


#==========| SUBNETS |==================
# public subnet
resource "aws_subnet" "public-subnet" {
  count = length(var.public-subnet-cidr)
  cidr_block              = tolist(var.public-subnet-cidr)[count.index]
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  depends_on = [
    aws_vpc.vpc
  ]

  tags      = {
    Name    = "${var.environment}-publicSubnet-${count.index + 1}"
    AvZones = data.aws_availability_zones.available.names[count.index]
    Env     = "${var.environment}-publicSubnet"
  }
}

# ----------------------------------------
# private subnet
resource "aws_subnet" "private-subnet" {
  count = length(var.private-subnet-cidr)
  cidr_block              = tolist(var.private-subnet-cidr)[count.index]
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  depends_on = [
    aws_vpc.vpc
  ]

  tags      = {
    Name    = "${var.environment}-privateSubnet-${count.index + 1}"
    AvZones = data.aws_availability_zones.available.names[count.index]
    Env     = "${var.environment}-privateSubnet"
  }
}
# ===========================================


# =========| ROUTE TABLES |==================
# route table for public subnet
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = var.default-cidr #0.0.0.0/0
    gateway_id = aws_internet_gateway.internet-gateway.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

# ---------------------------------------------
# route table for private subnet
resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.vpc.id
  count  = 2
  route {
    cidr_block     = var.default-cidr
    nat_gateway_id = element(aws_nat_gateway.nat-gateway.*.id, count.index)
  }

  tags = {
    Name = "Private Route Table ${count.index + 1}"
  }
}
# ============================================


# =========| ROUTE TABLE ASSOCIATIONS |===========

resource "aws_route_table_association" "public-subnet-route-table-association" {
  count          = 2
  subnet_id      = element(aws_subnet.public-subnet.*.id, count.index)
  route_table_id = aws_route_table.public-route-table.id
}

resource "aws_route_table_association" "private-subnet-route-table-association" {
  count          = 2
  subnet_id      = element(aws_subnet.private-subnet.*.id, count.index)
  route_table_id = element(aws_route_table.private-route-table.*.id, count.index)
}

# =================================================