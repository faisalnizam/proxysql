module "security_group" {
  providers = {
    aws = aws.eyewa-uat
  }

  source = "terraform-aws-modules/security-group/aws"

  name        = "uat-proxysql-ec2-sg"
  description = "Security group for proxysql over EC2 instance"
  vpc_id      = data.aws_vpc.vpc.id

  ingress_cidr_blocks = ["172.31.0.0/16", "172.31.128.0/19", "172.31.96.0/19", "86.96.29.251/32", "54.254.114.112/32"]
  ingress_rules       = ["http-80-tcp", "all-icmp", "ssh-tcp"]
  egress_rules        = ["all-all"]

  ingress_with_cidr_blocks = [
    {
      from_port   = 6032
      to_port     = 6033
      protocol    = "tcp"
      description = "ProxySQL Port"
      cidr_blocks = "172.31.0.0/16"
    },
    {
      from_port   = 6032
      to_port     = 6033
      protocol    = "tcp"
      description = "ProxySQL Port"
      cidr_blocks = "54.254.114.112/32"

    },
    {
      from_port   = 6080
      to_port     = 6080
      protocol    = "tcp"
      description = "ProxySQL Port"
      cidr_blocks = "54.254.114.112/32"

    },
  ]

  computed_ingress_with_source_security_group_id = [
    {
      from_port                = 6033
      to_port                  = 6033
      protocol                 = "tcp"
      source_security_group_id = "sg-0c8e31cc47b115b54" # Magento Admin Node - MySQL Traffic
    },
    {
      from_port                = 6033
      to_port                  = 6033
      protocol                 = "tcp"
      source_security_group_id = "sg-0c710f105aaf0a192" # Magento FE Node(S) - MySQL Traffic
    },
    {
      from_port                = 6032
      to_port                  = 6032
      protocol                 = "tcp"
      source_security_group_id = "sg-0b9b764733f74c929" # Pritunl VPN - ProxySQL Admin
    },
    {
      from_port                = 6033
      to_port                  = 6033
      protocol                 = "tcp"
      source_security_group_id = "sg-0b9b764733f74c929" # Pritunl VPN - MySQL Traffic
    },
    {
      from_port                = 6070
      to_port                  = 6070
      protocol                 = "tcp"
      source_security_group_id = "sg-05612f97a89436bbf" # Prometheus - REST API (metrics)
    },

  ]
  number_of_computed_ingress_with_source_security_group_id = 5
}



module "proxy_sql" {
  providers = {
    aws = aws.eyewa-uat
  }

  source = "../../modules/terraform-aws-ec2-instance/"

  instance_count = local.count

  name = "proxysql-uat"
  #ami                         = data.aws_ami.amazon_linux.id
  ami                         = "ami-0d058fe428540cd89"
  instance_type               = local.instance_type
  key_name                    = local.key_name
  subnet_ids                  = ["subnet-02b68abe50769ddc4", "subnet-0c87288570695befd"]
  vpc_security_group_ids      = [module.security_group.security_group_id]
  associate_public_ip_address = true

  user_data = file("./userdata/single/proxysql.sh")


  enable_volume_tags = false
  root_block_device = [
    {
      volume_type = "gp2"
      volume_size = 100
      tags = {
        Name = "proxysql-root-partition"
      }
    },
  ]

  tags = {
    "Env"      = "UAT"
    "Location" = "ap-southeast-1"
  }

}
