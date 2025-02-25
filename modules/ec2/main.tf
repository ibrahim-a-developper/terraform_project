resource "aws_instance" "instance" {
  for_each = var.instances

  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = local.key_name
  vpc_security_group_ids = var.vpc_security_group_ids
  subnet_id              = var.subnet_id
  # availability_zone      = each.value

  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install httpd -y
    sudo systemctl start httpd
    sudo systemctl enable httpd
    echo 'This is server *${each.key}* in AWS Region US-EAST-1 in AZ ${each.value} ' > /var/www/html/index.html
  EOF

  tags = {
    Name = "${each.key}_instance"
  }
}