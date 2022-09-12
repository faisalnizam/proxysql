/*

resource "aws_eip" "nat" {
  provider = aws.eyewa-uat
  count    = var.create_resources ? local.num_nat_gateways : 0
  vpc      = true
}

resource "aws_nat_gateway" "nat" {
  provider      = aws.eyewa-uat
  count         = var.create_resources ? local.num_nat_gateways : 0
  allocation_id = element(aws_eip.nat[*].id, count.index)
  subnet_id     = element(aws_subnet.private[*].id, count.index)

 tags = merge(
    {
      Name = "prxysql-${element(data.aws_availability_zones.all.names, count.index)}-natgw-${count.index}"
    }
  )

 
}


resource "aws_route" "nat" {

  provider               = aws.eyewa-uat
  count                  = var.create_resources && local.num_nat_gateways > 0 ? data.template_file.num_availability_zones.rendered : 0
  route_table_id         = element(aws_route_table.private[*].id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat[*].id, count.index % local.num_nat_gateways)

  depends_on = [
    aws_route_table.private,
  ]

  timeouts {
    create = "5m"
  }
  


}



resource "aws_subnet" "private" {

  provider          = aws.eyewa-uat
  count             = var.create_resources ? data.template_file.num_availability_zones.rendered : 0
  vpc_id            = data.aws_vpc.vpc.id
  availability_zone = element(data.aws_availability_zones.all.names, count.index)
  cidr_block = lookup(
    local.private_subnet_cidr_blocks,
    "AZ-${count.index}",
    cidrsubnet(element(data.aws_vpc.vpc.cidr_block_associations[*].cidr_block, 0), var.private_subnet_bits, count.index + var.subnet_spacing),
  )

  tags = merge(
    {
      Name = "prxysql-${element(data.aws_availability_zones.all.names, count.index)}-private-${count.index}"
    }
  )



}

resource "aws_route_table" "private" {

  provider = aws.eyewa-uat

  count            = var.create_resources ? data.template_file.num_availability_zones.rendered : 0
  vpc_id           = data.aws_vpc.vpc.id
  propagating_vgws = var.private_propagating_vgws

 tags = merge(
    {
      Name = "prxysql-${element(data.aws_availability_zones.all.names, count.index)}-routetables-${count.index}"
    }
  )

}


resource "aws_route_table_association" "private" {
  provider       = aws.eyewa-uat
  count          = var.create_resources ? data.template_file.num_availability_zones.rendered : 0
  subnet_id      = element(aws_subnet.private[*].id, count.index)
  route_table_id = element(aws_route_table.private[*].id, count.index)
}
 

*/
