variable "vpc_cidr_block" {
  type = string
}

variable "public_subnets" {
  type = map(string)
}

variable "private_subnets" {
  type = map(string)
}

variable "ami" {
  type = string
  default = "ami-053a45fff0a704a47"
  
}