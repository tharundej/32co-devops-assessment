# Secrets Manager Secret
resource "aws_secretsmanager_secret" "app_secrets" {
  name = "${var.app_name}-secrets"
}

# Secrets Manager Secret Version
resource "aws_secretsmanager_secret_version" "app_secrets_version" {
  secret_id = aws_secretsmanager_secret.app_secrets.id
  secret_string = jsonencode({
    DB_PASSWORD = var.db_password
    API_KEY     = "dummy-api-key"
  })
}