variable "vpc_id" {
  type = string
}

locals {
  allow_ports = [80, 443]
}
