resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "main_vpc"
  }
}

resource "aws_subnet" "public_subnets" {
  for_each = var.public_subnets

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value
  availability_zone = each.key
  tags = {
    Name = "public_subnet_${each.key}"
  }
}



resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "main_igw"
  }
}

# public route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name          = "public_rt"
    Environnement = "terraform"

  }
}

# association public route table 
resource "aws_route_table_association" "public_rt_association" {
  depends_on     = [aws_route_table.public_rt]
  for_each       = aws_subnet.public_subnets
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_rt.id
}

############## private

resource "aws_subnet" "private_subnets" {
  for_each = var.private_subnets

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value
  availability_zone = each.key
  tags = {
    Name = "private_subnet_${each.key}"
  }
}

resource "aws_eip" "eip" {
  domain = "vpc"
}


#nat gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public_subnets["us-east-1a"].id
  tags = {
    Name          = "gw NAT"
    Environnement = "terraform"

  }
  depends_on = [aws_internet_gateway.gw]
}

# private route table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name          = "private_rt"
    Environnement = "terraform"

  }
}

# association private route table 
resource "aws_route_table_association" "private_rt_association" {
  depends_on     = [aws_route_table.private_rt]
  for_each       = aws_subnet.private_subnets
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_rt.id
}