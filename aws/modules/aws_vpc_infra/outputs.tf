output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "VPC CIDR"
  value       = aws_vpc.this.cidr_block
}

output "public_subnets" {
  description = "Public Subnets"
  value       = aws_subnet.public
}

output "private_subnets" {
  description = "Private Subnets"
  value       = aws_subnet.private
}

output "public_routing_table" {
  description = "Public Routing Table"
  value       = aws_route_table.public
}