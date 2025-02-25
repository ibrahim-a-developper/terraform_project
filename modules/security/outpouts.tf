output "web_security_group_id" {
  value = aws_security_group.web_sg.id
}

output "alb_security_group_id" {
  value = aws_security_group.alb_sg.id
}

output "db_security_group_id" {
  value = aws_security_group.db_sg.id
}