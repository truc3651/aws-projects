output vpc {
    value = aws_vpc.main
}

output alb_sg {
    value = aws_security_group.alb_sg
}

output web_sg {
    value = aws_security_group.web_sg
}

output rds_sg {
    value = aws_security_group.rds_sg
}