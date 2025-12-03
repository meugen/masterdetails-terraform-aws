variable "region" {
  type        = string
  default     = "eu-central-1"
  description = "Region where masterdetails infrastructure should be provisioned"
}

variable "vpc_name" {
  type        = string
  default     = "apps"
  description = "VPC name where apps should be placed"
}

variable "subnet_num" {
  type        = number
  default     = 1
  description = "Number in VPC's subnet where masterdetails app should be placed"
}

variable "docker_io_username" {
  type        = string
  default     = "meugen"
  description = "Username for login to Docker Hub during build stage"
}

variable "docker_io_secret" {
  type        = string
  default     = ""
  description = "Secret with token for login to Docker Hub during build stage. Leave empty to skip"
}
