
variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"

}
variable "private_subnets" {
  default = {
    "us-east-1a" : "10.0.100.0/24"
    "us-east-1b" : "10.0.200.0/24"
  }
}

variable "public_subnets" {
  default = {
    "us-east-1a" : "10.0.10.0/24"
    "us-east-1b" : "10.0.20.0/24"
  }
}


variable "allow_ports" {
  type    = list(any)
  default = [80, 443]

}

variable "key_name" {
  type = string
  default = "my_key"
  
}





