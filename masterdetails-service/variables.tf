variable "github_conn" {
  type    = string
  default = "github-connection"
}

variable "github_repo" {
  type    = string
  default = "meugen/masterdetails-service"
}

variable "github_branch" {
  type    = string
  default = "main"
}

variable "region" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "subnet_num" {
  type = number
}

variable "docker_io_username" {
  type = string
}

variable "docker_io_secret" {
  type = string
}
