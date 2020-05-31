##
# IAM instance profile for the bastion instance
##
data "aws_iam_policy_document" "bastion" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "bastion" {
  name               = "${var.resource_name_prefix}-bastion"
  assume_role_policy = data.aws_iam_policy_document.bastion.json
  tags               = merge(var.tags, { "Name" = "${var.resource_name_prefix}-bastion" })
}

resource "aws_iam_role_policy" "bastion_basic_policy" {
  name   = "${var.resource_name_prefix}-bastion-basic-policy"
  role   = aws_iam_role.bastion.id
  policy = templatefile("${path.module}/templates/bastion-basic-instance-profile-policy.json", {})
}

resource "aws_iam_role_policy" "bastion_custom_policy" {
  count  = var.bastion_custom_iam_policy_provided ? 1 : 0
  name   = "${var.resource_name_prefix}-bastion-custom-policy"
  role   = aws_iam_role.bastion.id
  policy = var.bastion_custom_iam_policy
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.resource_name_prefix}-bastion"
  role = aws_iam_role.bastion.id
}

##
# Generate a random SSH port (when classic-bastion mode is enabled)
##
resource "random_integer" "ssh_port" {
  count = var.classic_bastion && var.deploy_bastion ? 1 : 0
  min   = 1024
  max   = 65535
}
locals {
  ssh_port = try(random_integer.ssh_port[0].result, 22)
}

##
# Security Group for the bastion instance
##
resource "aws_security_group" "bastion" {
  name   = "${var.resource_name_prefix}-bastion"
  vpc_id = var.vpc_id
  tags   = merge(var.tags, { "Name" = "${var.resource_name_prefix}-bastion" })
}

resource "aws_security_group_rule" "bastion_egress" {
  security_group_id = aws_security_group.bastion.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "bastion_ingress" {
  count             = var.classic_bastion && var.deploy_bastion ? 1 : 0
  security_group_id = aws_security_group.bastion.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = local.ssh_port
  to_port           = local.ssh_port
  cidr_blocks       = var.classic_bastion_ingress_cidr_blocks
}

##
# Generate a SSH key and an AWS key pair in order to be able to connect to the bastion EC2 instance (when classic-bastion mode is enabled)
##
resource "tls_private_key" "bastion" {
  count     = var.classic_bastion && var.deploy_bastion ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion" {
  count      = var.classic_bastion && var.deploy_bastion ? 1 : 0
  public_key = tls_private_key.bastion[0].public_key_openssh
}

resource "local_file" "bastion" {
  count    = var.classic_bastion && var.deploy_bastion ? 1 : 0
  content  = tls_private_key.bastion[0].private_key_pem
  filename = "./target/bastion-private-key.pem"
}

##
# Bastion instance
##
data "aws_ami" "bastion" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "image-type"
    values = ["machine"]
  }
}

resource "aws_instance" "bastion" {
  count = var.deploy_bastion ? 1 : 0

  ami           = data.aws_ami.bastion.id
  instance_type = var.bastion_instance_type
  key_name      = try(aws_key_pair.bastion[0].key_name, null)

  subnet_id                   = var.bastion_subnet_id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = var.bastion_subnet_is_public

  disable_api_termination              = false
  instance_initiated_shutdown_behavior = "terminate"

  user_data = base64encode(templatefile("${path.module}/templates/cloud-init.tpl.yml", {
    change_ssh_port_write_files_block = var.classic_bastion ? templatefile("${path.module}/templates/change-ssh-port-write-files-block.tpl.yml", {
      new_ssh_port = local.ssh_port
    }) : ""
    aditionnal_cloud_init_packages    = var.aditionnal_cloud_init_packages_provided ? var.aditionnal_cloud_init_packages : ""
    aditionnal_cloud_init_write_files = var.aditionnal_cloud_init_write_files_provided ? var.aditionnal_cloud_init_write_files : ""
    aditionnal_cloud_init_runcmd      = var.aditionnal_cloud_init_runcmd_provided ? var.aditionnal_cloud_init_runcmd : ""
    comment_change_ssh_port           = var.classic_bastion ? "" : "#"
    comment_kamikaze                  = var.kamikaze_bastion ? "" : "#"
    bastion_lifetime                  = var.bastion_lifetime
  }))

  iam_instance_profile = aws_iam_instance_profile.bastion.id

  tags        = merge(var.tags, { "Name" = "${var.resource_name_prefix}-bastion" })
  volume_tags = merge(var.tags, { "Name" = "${var.resource_name_prefix}-bastion" })
}