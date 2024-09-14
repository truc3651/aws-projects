variable "vpc_cidr" {
    type = string
}

variable "azs" {
  type = list(string)
}

variable "public_subnet_cidrs" {
    type = list(string)
}

variable "private_subnet_cidrs" {
    type = list(string)
}

variable "database_subnet_cidrs" {
    type = list(string)
}

variable "my_ip" {
  type = string
}