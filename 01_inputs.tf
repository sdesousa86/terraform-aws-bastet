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
  description = "Blabla"
  type        = bool
  default     = true
}

variable "session_duration" {
  description = "Blabla"
  type        = number
  default     = 1800
}

variable "kamikaze_bastion" {
  description = "Blabla"
  type        = bool
  default     = true
}

variable "bastion_lifetime" {
  description = "Blabla"
  type        = number
  default     = 1800
}

variable "vpc_id" {
  description = "Blabla"
  type        = string
}

variable "bastion_subnet_id" {
  description = "Blabla"
  type        = string
}

variable "bastion_custom_iam_policy" {
  description = "Blabla"
  type        = any
  default     = null
}

variable "bastion_instance_type" {
  description = "Blabla"
  type        = string
  default     = "t2.nano"
}
