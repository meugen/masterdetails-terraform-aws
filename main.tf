terraform {
  required_version = "~> 1.0"
}

module "masterdetails" {
  source = "./masterdetails-service"

  region = var.region
}
