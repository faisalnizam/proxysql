module "servers" {

  providers = {
    aws = aws.eyewa-uat
  }

  source = "../../modules/terraform-aws-asg/server-group" 

  name          = local.name
  size          = local.server_group_size
  instance_type = "t3.small"
  ami_id        = local.consul_image_id
  user_data     = data.template_file.user_data_consul.rendered

  aws_region = local.region
  vpc_id      = data.aws_vpc.vpc.id

  subnet_ids = ["subnet-02b68abe50769ddc4", "subnet-0c87288570695befd"]

  health_check_type         = "ELB"
  health_check_grace_period = 180
  alb_target_group_arns     = [aws_alb_target_group.servers.arn]
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
  allow_ssh_from_cidr_blocks  = ["172.31.0.0/16"]

  num_enis = 1

  ebs_volumes = [
    {
      type      = "gp2"
      size      = 40
      encrypted = false
    },
  ]

  custom_tags = {
    Name = "consul-uat-asg"
    consul-cluster = "uat-cluster"
  }
}


resource "aws_security_group_rule" "allow_inbound_http" {
    provider = aws.eyewa-uat

  type              = "ingress"
  from_port         = "0"
  to_port           = "65535"
  protocol          = "tcp"
  cidr_blocks       = ["172.31.0.0/16"]
  security_group_id = module.servers.security_group_id
}


module "alb" {
  
  providers = {
    aws = aws.eyewa-uat
  }

  source = "../../modules/terraform-aws-load-balancer/modules/alb/"
  alb_name            = local.name
  is_internal_alb     = false
  http_listener_ports = [8500]
  ssl_policy          = "ELBSecurityPolicy-TLS-1-1-2017-01"

  #aws_account_id = data.aws_caller_identity.current.account_id
  #aws_region     = local.region
  vpc_id         = data.aws_vpc.vpc.id
  vpc_subnet_ids            = ["subnet-02b68abe50769ddc4", "subnet-0c87288570695befd"]

}

resource "aws_security_group_rule" "allow_outbound_to_servers" {
    provider = aws.eyewa-uat

  type                     = "egress"
  from_port                = "0"
  to_port                  = "65535"
  protocol                 = "tcp"
  source_security_group_id = module.servers.security_group_id
  security_group_id        = module.alb.alb_security_group_id
}


resource "aws_alb_target_group" "servers" {
    provider = aws.eyewa-uat

  name     = local.name
  port     = local.consul_server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.vpc.id

  deregistration_delay = 10

  health_check {
    interval            = 15
    path                = "/v1/health/node/my-node"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-299"
  }
}

# Send all HTTP requests to our servers
resource "aws_alb_listener_rule" "all_http" {
    provider = aws.eyewa-uat

  listener_arn = module.alb.http_listener_arns[8500]
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }
  action {
    target_group_arn = aws_alb_target_group.servers.arn
    type             = "forward"
  }
}


data "aws_caller_identity" "current" {
  provider = aws.eyewa-uat

}


resource "aws_route53_record" "consul-uat" {
  provider = aws.eyewa-uat

  zone_id = "Z01493432D6VD69QOE1MR"
  name    = "uat-consul"
  type    = "CNAME"
  ttl     = "5"


  records = [module.alb.alb_dns_name]
}

