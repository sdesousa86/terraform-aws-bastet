data "external" "get_connection_url" {
  count   = var.deploy_bastion ? 1 : 0
  program = ["sh", "${path.module}/scripts/get_connection_url.sh"]
  query = {
    region           = var.region
    username         = local.cognito_user_name
    password         = random_password.bastet[0].result
    user_pool_id     = aws_cognito_user_pool.cognito_user_pool[0].id
    client_id        = aws_cognito_user_pool_client.cognito_user_pool_client[0].id
    identity_pool_id = aws_cognito_identity_pool.main[0].id
    session_duration = var.session_duration
    instance_id      = aws_instance.bastion[0].id
  }
  depends_on = [
    null_resource.create_cognito_user[0]
  ]
}

output "bastion_session_manager_url" {
  value = try(data.external.get_connection_url[0].result.aws_session_manager_console_url, null)
}

output "bastion_private_ip" {
  value = var.deploy_bastion ? aws_instance.bastion[0].private_ip : null
}

output "bastion_security_group_id" {
  value = aws_security_group.bastion.id
}

output "ssm_session_duration" {
  value = "${var.session_duration} seconds"
}

output "kamikaze_bastion_enabled" {
  value = var.kamikaze_bastion
}

output "bastion_lifetime" {
  value = var.kamikaze_bastion ? "${var.bastion_lifetime} seconds" : "infinite"
}

