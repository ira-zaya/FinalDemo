data "aws_availability_zones" "available" {}

variable "app_name" {
  default = "final_demo"
}

variable "vpc-cidr" {
  default      = "10.0.0.0/16"
  description  = "VPC CIDR Block"
  type         = string
}

variable "aws_region" {
  default = "eu-west-2"
}

variable "environment" {
  default = "dev"
}

variable "default-cidr" {
  type = string
  default = "0.0.0.0/0"
}

variable "eip" {
  description = "Create EIPs with different names"
  type = list(string)
  default = ["EIP 1", "EIP 2"]
}

variable "public-subnet-cidr" {
  type         = list(string)
  default      = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "private-subnet-cidr" {
  type         = list(string)
  default      = ["10.0.11.0/24", "10.0.21.0/24"]
}