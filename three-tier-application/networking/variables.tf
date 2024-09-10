variable "vpc_cidr" {
    type = string
}

variable "public_subnet_cidr" {
    type = list(string)
}

variable "private_subnet_cidr" {
    type = list(string)
}

variable "database_subnet_cidr" {
    type = list(string)
}