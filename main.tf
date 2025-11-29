terraform {
  required_version = "~> 1.14"
}

module "masterdetails" {
  source = "./masterdetails-service"

  region             = var.region
  vpc_name           = var.vpc_name
  subnet_num         = var.subnet_num
  docker_io_username = var.docker_io_username
  docker_io_secret   = var.docker_io_secret
}
