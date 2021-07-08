variable "insecure_password" {
  type = string
  default = "password"
}

resource "aws_secretsmanager_secret" "insecure_password" {
  name                    = "insecure_password"
  description             = "Security liability."
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "insecure_password" {
  secret_id     = aws_secretsmanager_secret.insecure_password.id
  secret_string = jsonencode(var.insecure_password)

  lifecycle {
    ignore_changes = [secret_string]
  }
}