output "rds_endpoint" {
  value = aws_db_instance.free_tier.endpoint
}

output "rds_port" {
  value = aws_db_instance.free_tier.port
}