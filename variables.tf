variable "alias" {
  description = "Alias to be defined for the account"
  type        = string
  default     = "eyewa_uat"
}

variable "private_subnet_cidr_blocks" {
  description = "A map listing the specific CIDR blocks desired for each private subnet. The key must be in the form AZ-0, AZ-1, ... AZ-n where n is the number of Availability Zones. If left blank, we will compute a reasonable CIDR block for each subnet."
  type        = map(string)
  default     = {}
  # Example:
  # default = {
  #    AZ-0 = "10.226.30.0/24"
  #    AZ-1 = "10.226.31.0/24"
  #    AZ-2 = "10.226.32.0/24"
  # }
}


variable "nlb_listeners" {
  default = [
    {
      protocol    = "TCP"
      target_port = "6033"
      health_port = "6033"
    }
  ]
}

variable "profile" {
  type    = string
  default = "aws.eyewa-uat"
}

variable "create_resources" {
  description = "If you set this variable to false, this module will not create any resources. This is used as a workaround because Terraform does not allow you to use the 'count' parameter on modules. By using this parameter, you can optionally create or not create the resources within this module."
  type        = bool
  default     = true
}

variable "num_availability_zones" {
  description = "How many AWS Availability Zones (AZs) to use. One subnet of each type (public, private) will be created in each AZ. All AZs will be used if you provide a value that is more than the number of AZs in a region. A value of null means all AZs should be used. For example, if you specify 3 in a region with 5 AZs, subnets will be created in just 3 AZs instead of all 5. On the other hand, if you specify 6 in the same region, all 5 AZs will be used with no duplicates (same as setting this to 5)."
  type        = number
  default     = null
}

variable "availability_zone_exclude_names" {
  description = "List of excluded Availability Zone names."
  type        = list(string)
  default     = []
}

variable "availability_zone_exclude_ids" {
  description = "List of excluded Availability Zone IDs."
  type        = list(string)
  default     = []
}

variable "availability_zone_state" {
  description = "Allows to filter list of Availability Zones based on their current state. Can be either \"available\", \"information\", \"impaired\" or \"unavailable\". By default the list includes a complete set of Availability Zones to which the underlying AWS account has access, regardless of their state."
  type        = string
  default     = null
}

variable "private_subnet_bits" {
  description = "Takes the CIDR prefix and adds these many bits to it for calculating subnet ranges.  MAKE SURE if you change this you also change the CIDR spacing or you may hit errors.  See cidrsubnet interpolation in terraform config for more information."
  type        = number
  default     = 5
}

variable "subnet_spacing" {
  description = "The amount of spacing between the different subnet types"
  type        = number
  default     = 10
}

variable "private_propagating_vgws" {
  description = "A list of Virtual Gateways that will propagate routes to private subnets. All routes from VPN connections that use Virtual Gateways listed here will appear in route tables of private subnets. If left empty, no routes will be propagated."
  type        = list(string)
  default     = []
}

variable "skip_rolling_deploy" {
  description = "If set to true, skip the rolling deployment, and destroy all the servers immediately. You should typically NOT enable this in prod, as it will cause downtime! The main use case for this flag is to make testing and cleanup easier. It can also be handy in case the rolling deployment code has a bug."
  type        = bool
  default     = false
}

variable "skip_health_check" {
  description = "If set to true, skip the health check, and start a rolling deployment without waiting for the server group to be in a healthy state. This is primarily useful if the server group is in a broken state and you want to force a deployment anyway."
  type        = bool
  default     = false
}

variable "deployment_batch_size" {
  description = "How many servers to deploy at a time during a rolling deployment. For example, if you have 10 servers and set this variable to 2, then the deployment will a) undeploy 2 servers, b) deploy 2 replacement servers, c) repeat the process for the next 2 servers."
  type        = number
  default     = 1
}

variable "alb_port" {
  description = "The port the ALB should listen on for HTTP requests"
  type        = number
  default     = 80
}

variable "ebs_volume_device_name" {
  description = "The device name to use for the EBS Volume attached to each server (e.g. /dev/xvdh)."
  type        = string
  default     = "/dev/xvdh"
}

variable "ebs_volume_mount_point" {
  description = "The path on the file system at which to mount the EBS volume (e.g. /foo/bar)."
  type        = string
  default     = "/asg-ebs-volume"
}

variable "ebs_volume_owner" {
  description = "The OS user who should own the mount point in var.ebs_volume_mount_point."
  type        = string
  default     = "ec2-user"
}
