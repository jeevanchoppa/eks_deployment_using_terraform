resource "aws_vpc" "project-eks-vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "project-eks-vpc"
  }
}

resource "aws_subnet" "project-eks-public-subnet" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.project-eks-vpc.id
  cidr_block        = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.aws_azs, count.index)

  tags = {
    Name = "project-eks-public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "project-eks-private-subnet" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.project-eks-vpc.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.aws_azs, count.index)

  tags = {
    Name = "project-eks-private-subnet-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "project-eks-igw" {
  vpc_id = aws_vpc.project-eks-vpc.id

  tags = {
    Name = "project-eks-igw"
  }
}

resource "aws_route_table" "project-eks-public-route-table" {
  vpc_id = aws_vpc.project-eks-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project-eks-igw.id

  }

  tags = {
    Name = "project-eks-public-route-table"
  }
}

resource "aws_route_table_association" "project-eks-public-route-table-assioc-public" {
  count          = length(aws_subnet.project-eks-public-subnet)
  subnet_id      = element(aws_subnet.project-eks-public-subnet[*].id, count.index)
  route_table_id = aws_route_table.project-eks-public-route-table.id
}

resource "aws_eip" "project-eks-eip" {
  #count      = length(aws_subnet.project-eks-public-subnet)
  domain     = "vpc"
  depends_on = [aws_internet_gateway.project-eks-igw]

  tags = {
    Name = "project-eks-eip"
  }
}

resource "aws_nat_gateway" "project-eks-nat-gateway" {
  #count         = length(aws_subnet.project-eks-public-subnet)
  #allocation_id = element(aws_eip.project-eks-eip, count.index)
  #subnet_id     = element(aws_subnet.project-eks-public-subnet, count.index)
  allocation_id = aws_eip.project-eks-eip.id
  subnet_id = aws_subnet.project-eks-public-subnet[0].id
  depends_on    = [aws_internet_gateway.project-eks-igw]

  tags = {
    Name = "project-eks-nat-gateway"
  }
}


resource "aws_route_table" "project-eks-private-route-table" {
  vpc_id = aws_vpc.project-eks-vpc.id

  route {
    cidr_block      = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.project-eks-nat-gateway.id
  }
  tags = {
    Name = "project-eks-private-route-table"
  }

}

resource "aws_route_table_association" "project-eks-private-aws_route_table_assoc-private" {
  count          = length(aws_subnet.project-eks-private-subnet)
  subnet_id      = element(aws_subnet.project-eks-private-subnet[*].id, count.index)
  route_table_id = aws_route_table.project-eks-private-route-table.id
}