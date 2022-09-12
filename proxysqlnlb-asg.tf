module "proxysql_servers" {

  providers = {
    aws = aws.eyewa-uat
  }

  source = "../../modules/terraform-aws-asg/server-group"

  name          = "proxysql"
  size          = local.server_group_size
  instance_type = "t3.medium"
  ami_id        = "ami-046677d87409c6216"
  user_data     = data.template_file.user_data.rendered

  aws_region = local.region
  vpc_id     = data.aws_vpc.vpc.id

  subnet_ids = ["subnet-02b68abe50769ddc4", "subnet-0c87288570695befd"]

  health_check_type         = "ELB"
  health_check_grace_period = 60
  alb_target_group_arns     = "${module.nlb.target_group_arns}"
  skip_rolling_deploy       = true
  skip_health_check         = true
  deployment_batch_size     = var.deployment_batch_size

  suspended_processes = [
    "Terminate",
    "ReplaceUnhealthy",
    "HealthCheck"
  ]

  key_pair_name               = local.key_name
  associate_public_ip_address = true
  allow_ssh_from_cidr_blocks  = ["0.0.0.0/0"]

  num_enis = 1

  ebs_volumes = [
    {
      type      = "gp2"
      size      = 40
      encrypted = false
    },
  ]

  custom_tags = {
    Name           = "proxysql-uat-asg"
    consul-cluster = "uat-cluster"
    proxysq-sql    = "yes"

  }
}

resource "aws_security_group_rule" "proxysql_allow_inbound_http" {
  provider = aws.eyewa-uat

  type              = "ingress"
  from_port         = "0"
  to_port           = "65535"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.proxysql_servers.security_group_id
}

resource "aws_security_group_rule" "proxysql_allow_outbound_to_servers" {
  provider = aws.eyewa-uat

  type                     = "egress"
  from_port                = "0"
  to_port                  = "65535"
  protocol                 = "tcp"
  security_group_id        = module.proxysql_servers.security_group_id
  source_security_group_id = module.proxysql_servers.security_group_id
}


module "nlb" {

  providers = {
    aws = aws.eyewa-uat
  }


  source = "../../modules/terraform-aws-alb/"

  name = "proxysql-nlb"

  load_balancer_type = "network"
  internal           = true
  vpc_id             = data.aws_vpc.vpc.id

  subnets = ["subnet-02b68abe50769ddc4", "subnet-0c87288570695befd"]



  target_groups = [
    {
      name_prefix          = "psqltg"
      backend_protocol     = "TCP"
      backend_port         = 6033
      target_type          = "instance"
      preserve_client_ip   = true
      deregistration_delay = 10
      health_check = {
        protocol          = "TCP"
        enabled           = true
        target            = "TCP"
        interval          = 30
        port              = "6033"
        healthy_threshold = 3
      }
    }
  ]


  http_tcp_listeners = [
    {
      port               = 6033
      protocol           = "TCP"
      target_group_index = 0
    }
  ]

  tags = {
    Environment = "ProxySQL-NLB"
  }
}


data "aws_caller_identity" "proxysql_current" {
  provider = aws.eyewa-uat

}

resource "aws_route53_record" "proxysql-uat" {
  provider = aws.eyewa-uat

  zone_id = "Z01493432D6VD69QOE1MR"
  name    = "uat-proxysql"
  type    = "CNAME"
  ttl     = "5"


  records = [module.nlb.lb_dns_name]
}


