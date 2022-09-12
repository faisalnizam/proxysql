locals {

  env               = "uat"
  region            = "ap-southeast-1"
  org               = "eyewa"
  profile           = "${local.org}_uat"
  profile_s3        = "${local.org}_s3"
  alias             = "${local.org}_uat"
  key_name          = "${local.org}-proxysql-uat-key"
  tfprofile         = "aws.${local.org}-${local.env}"
  name              = "consul-uat"
  server_text       = "test"
  instance_type     = "t3.medium"
  consul_image_id   = "ami-076dd640bbeef55f3"
  server_group_size = "3"
  proxysql_alb_port = 6033
  vpc_cidr          = "172.31.0.0/16"

  private_subnet_cidr_blocks = {
    AZ-0 = "172.31.200.0/24"
    AZ-1 = "172.31.210.0/24"
    AZ-2 = "172.31.220.0/24"
  }

  num_nat_gateways = 3

  count         = "0"
  load_balancer = true
  listener_port = 22


  consul_server_port = "8500"
  server_port        = "8500"
  elb_port           = "8500"

}
