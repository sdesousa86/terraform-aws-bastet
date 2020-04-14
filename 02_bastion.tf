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
  role   = aws_iam_role.bastion.name
  policy = templatefile("${path.module}/templates/bastion-basic-instance-profile-policy.json", {})
}

resource "aws_iam_role_policy" "bastion_custom_policy" {
  count  = var.bastion_custom_iam_policy != null ? 1 : 0
  name   = "${var.resource_name_prefix}-bastion-custom-policy"
  role   = aws_iam_role.bastion.name
  policy = var.bastion_custom_iam_policy
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.resource_name_prefix}-bastion"
  role = aws_iam_role.bastion.name
}

##
# Security Group for the bastion instance
##
resource "aws_security_group" "bastion" {
  name   = "${var.resource_name_prefix}-bastion"
  vpc_id = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, { "Name" = "${var.resource_name_prefix}-bastion" })
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

  subnet_id                   = var.bastion_subnet_id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = false

  disable_api_termination              = false
  instance_initiated_shutdown_behavior = "terminate"

  user_data = base64encode(templatefile("${path.module}/templates/cloud-init.tpl.yml", {
    comment          = var.kamikaze_bastion ? "" : "#"
    bastion_lifetime = var.bastion_lifetime
  }))

  iam_instance_profile = aws_iam_instance_profile.bastion.name

  tags        = merge(var.tags, { "Name" = "${var.resource_name_prefix}-bastion" })
  volume_tags = merge(var.tags, { "Name" = "${var.resource_name_prefix}-bastion" })
}