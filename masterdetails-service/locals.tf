locals {
  project_name = "masterdetails"
  build_role_name = "${local.project_name}-build-role"
  deploy_role_name = "${local.project_name}-deploy-role"
  log_group = "${local.project_name}-log-group"
  log_stream = "${local.project_name}-log-stream"
  service_name = "${local.project_name}-service"
  subnet_name = "${local.project_name}-subnet"
  subnet_group_name = "${local.project_name}-subnet-group"
  apprunner_vpc_name = "${local.project_name}-apprunner-vpc-connector"
  db_name = "${local.project_name}-db"
  cache_name = "${local.project_name}-cache"
  newbits = 4
}
