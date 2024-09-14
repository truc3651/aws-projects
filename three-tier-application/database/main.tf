resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db_subnet_group"
  subnet_ids = [for subnet in var.database_subnet : subnet.id]
}

resource "aws_kms_key" "db_key" {
    enable_key_rotation = false
}

resource "aws_db_instance" "default" {
  db_name              = var.db_name
  allocated_storage = 10
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = var.username
  manage_master_user_password = true
  master_user_secret_kms_key_id = aws_kms_key.db_key.key_id
  parameter_group_name = "default.mysql8.0"
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  skip_final_snapshot = true
}