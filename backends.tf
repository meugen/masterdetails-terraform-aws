terraform {
  backend "s3" {
    bucket  = "masterdetails-terraform-state"
    key     = "masterdetails.tfstate"
    region  = "eu-central-1"
    encrypt = true
  }
}
