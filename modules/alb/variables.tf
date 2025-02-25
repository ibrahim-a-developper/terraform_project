variable "vpc_id" {
  type = string
}



variable "instances" {
  type = any
  
}
variable "target_id" {
  type = string
  
}

variable "autoscaling_group_name" {
  type = string

}
variable "subnets" {
  type = set(string)


}
variable "security_groups" {
  type = list(string)

}
