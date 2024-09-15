output vpc {
    value = aws_vpc.main
}

output subnets {
    value = {
        public = aws_subnet.public_subnets
        private = aws_subnet.private_subnets
        database = aws_subnet.database_subnets
    }
}

output sg {
    value = {
        alb_web_server_sg = aws_security_group.alb_sg
        web_server_sg = aws_security_group.web_sg
        alb_backend_sg = aws_security_group.backend_alb_sg
        backend_sg = aws_security_group.backend_sg
        database_sg = aws_security_group.database_sg
    }
}
