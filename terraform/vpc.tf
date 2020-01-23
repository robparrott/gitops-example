#
# VPC Resources
#  * VPC
#  * Subnets
#  * Internet Gateway
#  * Route Table
#

resource "aws_vpc" "eks-sandbox" {
  cidr_block = "10.0.0.0/16"

  tags = map(
    "Name", "eks-sandbox-node",
    "kubernetes.io/cluster/${var.cluster-name}", "shared",
  )
}

resource "aws_subnet" "eks-sandbox" {
  count = 3

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = "10.0.${count.index}.0/24"
  vpc_id            = aws_vpc.eks-sandbox.id

  tags = map(
    "Name", "terraform-eks-eks-sandbox-node",
    "kubernetes.io/cluster/${var.cluster-name}", "shared",
  )
}

resource "aws_internet_gateway" "eks-sandbox" {
  vpc_id = aws_vpc.eks-sandbox.id

  tags = {
    Name = "terraform-eks-sandbox"
  }
}

resource "aws_route_table" "eks-sandbox" {
  vpc_id = aws_vpc.eks-sandbox.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks-sandbox.id
  }
}

resource "aws_route_table_association" "eks-sandbox" {
  count = 3

  subnet_id      = aws_subnet.eks-sandbox.*.id[count.index]
  route_table_id = aws_route_table.eks-sandbox.id
}
