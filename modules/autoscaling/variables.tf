
variable "image_id" {
  type = string
}

variable "instance_type" {
  type = string
}





variable "lb_target_group_arn" {
  # type = string
}

variable "vpc_security_group_ids" {
  type = set(string)
  
}

variable "vpc_zone_identifier" {
  type = set(string)

  
}