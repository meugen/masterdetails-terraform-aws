terraform {
  required_version = "~> 1.0"
}

module "masterdetails" {
  source = "./masterdetails-service"

  region = var.region
  vpc_name = var.vpc_name
  subnet_num = var.subnet_num
}
