data "template_file" "num_availability_zones" {

  template = (
    var.num_availability_zones == null
    ? length(data.aws_availability_zones.all.names)
    : min(var.num_availability_zones, length(data.aws_availability_zones.all.names))
  )


}

/*
data "aws_subnet_ids" "subnet_ids" {
  provider = aws.eyewa-uat
  depends_on = [
    aws_route_table.private,
  ]

  vpc_id = data.aws_vpc.vpc.id

  tags = {
    Name = "*-private-*"
  }

}
*/


#data "template_file" "init" {
#  template = file("${path.module}/userdata/run-proxysql.sh")
#}

#resource "template_file" "web-userdata" {
#  template = "./userdata/proxysql.sh"
#}


data "aws_ami" "amazon_linux" {
  provider = aws.eyewa-uat

  most_recent = true
  owners      = ["amazon"]

  filter {
    name = "name"

    values = [
      "amzn-ami-hvm-*-x86_64-gp2",
    ]
  }

  filter {
    name = "owner-alias"

    values = [
      "amazon",
    ]
  }
}


data "aws_availability_zones" "all" {

  provider         = aws.eyewa-uat
  state            = var.availability_zone_state
  exclude_names    = var.availability_zone_exclude_names
  exclude_zone_ids = var.availability_zone_exclude_ids

}

data "aws_vpc" "vpc" {
  provider = aws.eyewa-uat

  tags = {
    Name = "*default*"
  }

}


data "aws_iam_policy_document" "instance_role" {
  provider = aws.eyewa-uat

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/userdata/run-proxysql.sh")
}

data "template_file" "user_data_consul" {
  template = file("${path.module}/userdata/run-consul.sh")
}



data "aws_ami" "ubuntu" {
  provider = aws.eyewa-uat

  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "image-type"
    values = ["machine"]
  }

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}


