variable load_balancer_sg {
    type = any
}

variable web_server_sg {
    type = any
}

variable backend_sg {
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