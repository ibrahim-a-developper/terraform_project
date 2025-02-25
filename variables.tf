variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type = map(string)
  default = {
    "us-east-1a" = "10.0.10.0/24"
    "us-east-1b" = "10.0.20.0/24"
  }
}

variable "private_subnets" {
  type = map(string)
  default = {
    "us-east-1a" = "10.0.100.0/24"
    "us-east-1b" = "10.0.200.0/24"
  }
}

variable "allow_ports" {
  type    = list(number)
  default = [80, 443]
}


variable "ami" {
  type = string
  default = "ami-053a45fff0a704a47"
  
}

variable "instance_type" {
  type = string
  default =  "t3.micro"
  
}