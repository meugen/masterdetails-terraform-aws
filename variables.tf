variable "region" {
  type = string
  default = "eu-central-1"
  description = "Region where masterdetails infrastructure should be provisioned"
}

variable "vpc_name" {
  type = string
  default = "apps"
  description = "VPC name where apps should be placed"
}

variable "subnet_num" {
  type = number
  default = 1
  description = "Number in VPC's subnet where masterdetails app should be placed"
}
