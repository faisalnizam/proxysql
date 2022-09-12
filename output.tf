output "vpc_id" {

  value = data.aws_vpc.vpc.id

}

output "cidr_block" {

  value = element(data.aws_vpc.vpc.cidr_block_associations[*].cidr_block, 0)

}

output "instance_ids" {

  value = module.proxy_sql.id
}

output "privateips" {

  value = module.proxy_sql.private_ip
}

output "eni_private_ips_proxysql" {

  value = module.proxysql_servers.eni_private_ips
}

output "arn" {

  value = module.nlb.target_group_arns
}
/* 
output "asg_name" {
  value = module.asg.asg_name
}

output "asg_unique_id" {
  value = module.asg.asg_unique_id
}

output "elb_dns_name" {
  value = aws_elb.load_balancer.dns_name
}
*/
