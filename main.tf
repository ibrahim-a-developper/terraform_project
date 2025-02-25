provider "aws" {
  region  = "us-east-1"
  profile = "terraform_dev"
}

module "vpc" {
  source = "./modules/vpc"

  vpc_cidr_block  = var.vpc_cidr_block
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}

module "security" {
  source = "./modules/security"
  vpc_id = module.vpc.vpc_id
}

module "instances" {
  source                 = "./modules/ec2"
  for_each               = { "web" = "us-east-1a", "app" = "us-east-1b" }
  ami                    = var.ami
  instance_type          = var.instance_type
  vpc_id                 = module.vpc.vpc_id
  subnet_id              = module.vpc.private_subnets[each.value].id
  vpc_security_group_ids = [module.security.web_security_group_id]
}



module "alb" {
  source = "./modules/alb"
  for_each = {
    for k, v in module.instances :
    k => v
  }
  instances = module.instances
  vpc_id    = var.vpc_cidr_block
  target_id = each.value.id

  autoscaling_group_name = module.autoscaling.autoscaling_group_name
  security_groups        = [module.security.alb_security_group_id]
  subnets                = [for subnet in module.vpc.public_subnets : subnet.id]
}




module "autoscaling" {
  source        = "./modules/autoscaling"
  image_id      = var.ami
  instance_type = var.instance_type

  vpc_security_group_ids = [module.security.web_security_group_id]

  vpc_zone_identifier = [for subnet in module.vpc.private_subnets : subnet.id]
  lb_target_group_arn = module.alb.lb_target_group_arn

}
module "rds" {
  source     = "./modules/rds"
  subnet_ids = [for subnet in module.vpc.private_subnets : subnet.id]
}
