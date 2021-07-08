resource "random_password" "password" {
  length           = 32
  special          = false
}

resource "aws_secretsmanager_secret" "secure_password" {
  name                    = "secure_password"
  description             = "Incredibly secrect secure password."
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "secure_password" {
  secret_id     = aws_secretsmanager_secret.secure_password.id
  secret_string = jsonencode(random_password.password.result)

  lifecycle {
    ignore_changes = [secret_string]
  }
}