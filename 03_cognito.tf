#####################
# Cognito User Pool #
#####################
resource "aws_cognito_user_pool" "cognito_user_pool" {
  count                    = var.deploy_bastion ? 1 : 0
  name                     = "${var.resource_name_prefix}-user-pool"
  alias_attributes         = ["email"]
  auto_verified_attributes = ["email"]
  password_policy {
    minimum_length                   = 24
    require_uppercase                = true
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = false
    temporary_password_validity_days = 7
  }
  tags = merge(var.tags, { "Name" = "${var.resource_name_prefix}-user-pool" })
}

resource "aws_cognito_user_pool_client" "cognito_user_pool_client" {
  count               = var.deploy_bastion ? 1 : 0
  name                = "${var.resource_name_prefix}-user-pool-client"
  user_pool_id        = aws_cognito_user_pool.cognito_user_pool[0].id
  explicit_auth_flows = ["ADMIN_NO_SRP_AUTH", "USER_PASSWORD_AUTH"]
  generate_secret     = false
}

##################
## Cognito user ##
##################
resource "random_password" "bastet" {
  count       = var.deploy_bastion ? 1 : 0
  length      = 24
  upper       = true
  min_upper   = 1
  lower       = true
  min_lower   = 1
  number      = true
  min_numeric = 1
  special     = false
}

locals {
  cognito_user_name = "bastet"
  cognito_user_mail = "bastet@goddess.cats"
}

resource "null_resource" "create_cognito_user" {
  count = var.deploy_bastion ? 1 : 0
  provisioner "local-exec" {
    command = "sh ${path.module}/scripts/create_cognito_user.sh"
    environment = {
      "AWS_REGION_CODE"     = var.region
      "AWS_CLI_PROFILE"     = var.aws_cli_profile
      "USER_NAME"           = local.cognito_user_name
      "USER_EMAIL"          = local.cognito_user_mail
      "USER_PASSWORD"       = random_password.bastet[0].result
      "USER_POOL_ID"        = aws_cognito_user_pool.cognito_user_pool[0].id
      "USER_POOL_CLIENT_ID" = aws_cognito_user_pool_client.cognito_user_pool_client[0].id
    }
  }
  depends_on = [
    aws_cognito_user_pool.cognito_user_pool[0],
    aws_cognito_user_pool_client.cognito_user_pool_client[0]
  ]
}

#########################
# Cognito Identity Pool #
#########################
resource "aws_cognito_identity_pool" "main" {
  count                            = var.deploy_bastion ? 1 : 0
  identity_pool_name               = "${replace(var.resource_name_prefix, "-", "_")}_cognito_identity_pool"
  allow_unauthenticated_identities = false
  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.cognito_user_pool_client[0].id
    provider_name           = "cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.cognito_user_pool[0].id}"
    server_side_token_check = false
  }
  tags = merge(var.tags, { "Name" = "${var.resource_name_prefix}-cognito-identity-pool" })
}

############################
## Identity Pool IAM Role ##
############################
resource "aws_iam_role" "authenticated" {
  count = var.deploy_bastion ? 1 : 0
  name  = "${var.resource_name_prefix}-bastet"
  assume_role_policy = templatefile("${path.module}/templates/authenticated-role-assume-role-policy.tpl.json", {
    aws_cognito_identity_pool_main_id = aws_cognito_identity_pool.main[0].id
  })
  max_session_duration = 43200
  tags                 = merge(var.tags, { "Name" = "${var.resource_name_prefix}-bastet" })
}

resource "aws_iam_role" "unauthenticated" {
  count = var.deploy_bastion ? 1 : 0
  name  = "${var.resource_name_prefix}-unauthenticated-bastet"
  assume_role_policy = templatefile("${path.module}/templates/unauthenticated-role-assume-role-policy.tpl.json", {
    aws_cognito_identity_pool_main_id = aws_cognito_identity_pool.main[0].id
  })
  tags = merge(var.tags, { "Name" = "${var.resource_name_prefix}-unauthenticated-bastet" })
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy" "authenticated" {
  count = var.deploy_bastion ? 1 : 0
  name  = "${var.resource_name_prefix}-bastet"
  role  = aws_iam_role.authenticated[0].id
  policy = templatefile("${path.module}/templates/authenticated-role-policy.tpl.json", {
    instance_arn = aws_instance.bastion[0].arn
    region       = var.region
    account_id   = data.aws_caller_identity.current.account_id
  })
}

resource "aws_cognito_identity_pool_roles_attachment" "main" {
  count            = var.deploy_bastion ? 1 : 0
  identity_pool_id = aws_cognito_identity_pool.main[0].id
  roles = {
    "authenticated"   = aws_iam_role.authenticated[0].arn
    "unauthenticated" = aws_iam_role.unauthenticated[0].arn
  }
}