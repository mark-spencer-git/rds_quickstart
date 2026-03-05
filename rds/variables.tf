# assign TF_VAR_db_password in environment variables to pull from environment variables
variable "DB_PASSWORD" {
  sensitive = true
}