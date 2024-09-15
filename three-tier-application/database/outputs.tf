output db {
  value = {
    host = aws_db_instance.default.address
    port = aws_db_instance.default.port
    value = aws_db_instance.default.username
  }
}
