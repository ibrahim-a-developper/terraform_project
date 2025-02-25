variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

locals {
  key_name = "my_key"
}
# variable "key_name" {
#   type = string
#   default = "my_key"
# }

variable "vpc_security_group_ids" {
  type = list(any)
}

variable "ami" {
  type = string

}
variable "instance_type" {
  type = string

}

variable "instances" {
  type    = map(any)
  default = { "web" = "us-east-1a", "app" = "us-east-1b" }

}
