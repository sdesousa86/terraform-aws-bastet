variable "aws_cli_profile" {
  description = "The aws-cli profile name that will be use (if the provided aws-cli profile is not valid, the script that use it will try to use your system default AWS credentials)"
  type        = string
  default     = "my-aws-cli-profile"
}

variable "resource_name_prefix" {
  description = "Used to build name of the module resources"
  type        = string
}

variable "region" {
  description = "AWS region where the resources will be created"
  type        = string
}

variable "tags" {
  description = "Map of tags to set for each resources that accept tags"
  type        = map(string)
  default     = {}
}

variable "deploy_bastion" {
  description = "Activate or not the EC2 instance bastion creation"
  type        = bool
  default     = true
}

variable "classic_bastion" {
  description = "Switch to classic-bastion mode (SSH key + random SSH port)"
  type        = bool
  default     = false
}

variable "classic_bastion_ingress_cidr_blocks" {
  description = "IPs to whithelist for classic-bastion access"
  type        = list(string)
  default     = null
}
locals {
  is_classic_bastion_ingress_cidr_blocks_valid = (var.classic_bastion == true && var.classic_bastion_ingress_cidr_blocks == null) ? ["NO"] : ["YES"]
  validate_classic_bastion_ingress_cidr_blocks = index(local.is_classic_bastion_ingress_cidr_blocks_valid, "YES")
}


variable "session_duration" {
  description = "Time during which tokenized URL will be valid (in seconds). Min: 900 seconds (15 minutes) - Max: 43200 seconds (12 hours)"
  type        = number
  default     = 900
}
locals {
  is_session_duration_valid = (var.session_duration >= 900 && var.session_duration <= 43200) ? ["YES"] : ["NO"]
  validate_session_duration = index(local.is_session_duration_valid, "YES")
}

variable "kamikaze_bastion" {
  description = "Activate or not the auto-shutdown (kamikaze) behavior of your bastion"
  type        = bool
  default     = true
}

variable "bastion_lifetime" {
  description = "Time, in seconds, before your bastion will automatically shutdown (only if kamikaze_bastion = true)"
  type        = number
  default     = 1800
}

variable "vpc_id" {
  description = "The ID of your AWS VPC where your bastion will run"
  type        = string
}

variable "bastion_subnet_id" {
  description = "The ID of the subnet where your bastion will run"
  type        = string
}

variable "bastion_subnet_is_public" {
  description = "You must indicate if the provided subnet is a public subnet (Route table with route to an Internet Gateway) or not."
  type        = bool
}
locals {
  is_bastion_subnet_is_public_valid = (var.classic_bastion == true && var.bastion_subnet_is_public == false) ? ["NO"] : ["YES"]
  validate_bastion_subnet_is_public = index(local.is_bastion_subnet_is_public_valid, "YES")
}


variable "bastion_custom_iam_policy" {
  description = "A custom IAM rôle policy JSON object for your bastion EC2 instance (optional)"
  type        = any
  default     = null
}

variable "bastion_instance_type" {
  description = "The bastion instance type"
  type        = string
  default     = "t2.nano"
}