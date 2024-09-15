variable sg {
    type = any
}

variable vpc {
    type = any
}

variable subnets {
    type = object({
      public = any
      private = any
    })
}

variable key_pair_name{
    type = string
}

variable hosted_zone_name {
    type = string
}

variable web_server_dns_name {
    type = string
}
    