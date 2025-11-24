data "aws_vpc" "vpc" {
  tags = {
    Name = var.vpc_name
  }
}

data "aws_availability_zones" "az_list" {
  state = "available"
}

resource "aws_subnet" "subnets" {
  count = length(data.aws_availability_zones.az_list.names)

  vpc_id = data.aws_vpc.vpc.id
  cidr_block = cidrsubnet(data.aws_vpc.vpc.cidr_block, local.newbits, var.subnet_num + count.index)
  availability_zone = data.aws_availability_zones.az_list.names[count.index]

  tags = {
    Name = "${local.subnet_name}-${data.aws_availability_zones.az_list.names[count.index]}"
  }
}

resource "aws_security_group" "sg_https_ingress" {
  vpc_id = data.aws_vpc.vpc.id
  name = "${local.project_name}-sg-https-ingress"
  description = "Ingress security group for HTTPS"

  tags = {
    Name = "${local.project_name}-sg-https-ingress"
  }
}

resource "aws_vpc_security_group_ingress_rule" "sg_https_ingress_rule" {
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.sg_https_ingress.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 443
  to_port = 443
}

# resource "aws_security_group" "sg_https_egress" {
#   vpc_id = data.aws_vpc.vpc.id
#   name = "${local.project_name}-sg-https-egress"
#   description = "Egress security group for HTTPS"
#
#   tags = {
#     Name = "${local.project_name}-sg-https-egress"
#   }
# }
#
# resource "aws_vpc_security_group_egress_rule" "sg_https_egress_rule" {
#   ip_protocol       = "tcp"
#   security_group_id = aws_security_group.sg_https_egress.id
#   cidr_ipv4 = "0.0.0.0/0"
#   from_port = 443
#   to_port = 443
# }
#
# resource "aws_vpc_security_group_egress_rule" "sg_tcp_dns_egress_rule" {
#   ip_protocol       = "tcp"
#   security_group_id = aws_security_group.sg_https_egress.id
#   cidr_ipv4 = "0.0.0.0/0"
#   from_port = 53
#   to_port = 53
# }
#
# resource "aws_vpc_security_group_egress_rule" "sg_udp_dns_egress_rule" {
#   ip_protocol       = "udp"
#   security_group_id = aws_security_group.sg_https_egress.id
#   cidr_ipv4 = "0.0.0.0/0"
#   from_port = 53
#   to_port = 53
# }

resource "aws_security_group" "sg_postgres_ingress" {
  vpc_id = data.aws_vpc.vpc.id
  name = "${local.project_name}-sg-postgres-ingress"
  description = "Ingress security group for PostgreSQL"

  tags = {
    Name = "${local.project_name}-sg-postgres-ingress"
  }
}

resource "aws_vpc_security_group_ingress_rule" "sg_postgres_ingress_rule" {
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.sg_postgres_ingress.id
  cidr_ipv4 = data.aws_vpc.vpc.cidr_block
  from_port = 5432
  to_port = 5432
}

resource "aws_security_group" "sg_postgres_egress" {
  vpc_id = data.aws_vpc.vpc.id
  name = "${local.project_name}-sg-postgres-egress"
  description = "Egress security group for PostgreSQL"

  tags = {
    Name = "${local.project_name}-sg-postgres-egress"
  }
}

resource "aws_vpc_security_group_egress_rule" "sg_postgres_egress_rule" {
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.sg_postgres_egress.id
  cidr_ipv4 = data.aws_vpc.vpc.cidr_block
  from_port = 5432
  to_port = 5432
}

resource "aws_security_group" "sg_redis_ingress" {
  vpc_id = data.aws_vpc.vpc.id
  name = "${local.project_name}-sg-redis-ingress"
  description = "Ingress security group for Redis"

  tags = {
    Name = "${local.project_name}-sg-regis-ingress"
  }
}

resource "aws_vpc_security_group_ingress_rule" "sg_redis_ingress_rule" {
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.sg_redis_ingress.id
  cidr_ipv4 = data.aws_vpc.vpc.cidr_block
  from_port = 6379
  to_port = 6379
}

resource "aws_security_group" "sg_redis_egress" {
  vpc_id = data.aws_vpc.vpc.id
  name = "${local.project_name}-sg-redis-egress"
  description = "Egress security group for Redis"

  tags = {
    Name = "${local.project_name}-sg-redis-egress"
  }
}

resource "aws_vpc_security_group_egress_rule" "sg_redis_egress_rule" {
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.sg_redis_egress.id
  cidr_ipv4 = data.aws_vpc.vpc.cidr_block
  from_port = 6379
  to_port = 6379
}

resource "aws_db_subnet_group" "subnet_group" {
  name = local.subnet_group_name
  subnet_ids = aws_subnet.subnets[*].id

  tags = {
    Name = local.subnet_group_name
  }
}

resource "aws_db_instance" "db" {
  instance_class = "db.m5.large"
  engine = "postgres"
  engine_version = "17.6"
  identifier = local.db_name
  db_name = "masterdetails"
  db_subnet_group_name = aws_db_subnet_group.subnet_group.name
  manage_master_user_password = true
  username = "masterdetails"
  vpc_security_group_ids = [aws_security_group.sg_postgres_ingress.id]
  skip_final_snapshot = true
  allocated_storage = 10
  max_allocated_storage = 100
}

data "aws_iam_policy_document" "assume_deploy_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = [
        "build.apprunner.amazonaws.com",
        "tasks.apprunner.amazonaws.com"
      ]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "masterdetails_deploy_role" {
  name = local.deploy_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_deploy_role.json
}

data "aws_iam_policy_document" "masterdetails_deploy_role" {
  statement {
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:DescribeImages"
    ]

    resources = [
      aws_ecr_repository.repo.arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      aws_db_instance.db.master_user_secret[0].secret_arn
    ]
  }
}

resource "aws_iam_role_policy" "masterdetails_deploy_policy" {
  role = aws_iam_role.masterdetails_deploy_role.name
  policy = data.aws_iam_policy_document.masterdetails_deploy_role.json
}

resource "time_sleep" "deploy_wait_10s" {
  depends_on = [aws_iam_role_policy.masterdetails_deploy_policy]
  create_duration = "10s"
}

resource "aws_elasticache_serverless_cache" "cache" {
  engine = "valkey"
  name   = local.cache_name

  cache_usage_limits {
    data_storage {
      maximum = 10
      unit = "GB"
    }
    ecpu_per_second {
      maximum = 5000
    }
  }

  security_group_ids = [aws_security_group.sg_redis_ingress.id]
  subnet_ids = aws_subnet.subnets[*].id

  tags = {
    Name = local.cache_name
  }
}

resource "aws_apprunner_vpc_connector" "apprunner_vpc" {
  security_groups = [
    aws_security_group.sg_https_ingress.id,
    aws_security_group.sg_postgres_egress.id,
    aws_security_group.sg_redis_egress.id
  ]
  subnets = aws_subnet.subnets[*].id
  vpc_connector_name = local.apprunner_vpc_name

  tags = {
    Name = local.apprunner_vpc_name
  }
}

resource "aws_apprunner_auto_scaling_configuration_version" "auto_scaling" {
  auto_scaling_configuration_name = local.auto_scaling_name

  max_concurrency = 50
  max_size = 10
  min_size = 2

  tags = {
    Name = local.auto_scaling_name
  }
}

resource "aws_apprunner_service" "service" {
  depends_on = [time_sleep.deploy_wait_10s]

  service_name = local.service_name
  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration_version.auto_scaling.arn

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.masterdetails_deploy_role.arn
    }
    image_repository {
      image_identifier = "${aws_ecr_repository.repo.repository_url}:latest"
      image_repository_type = "ECR"

      image_configuration {
        port = "8080"

        runtime_environment_secrets = {
          PGSQL_PASSWORD = aws_db_instance.db.master_user_secret[0].secret_arn
        }

        runtime_environment_variables = {
          PGSQL_HOSTNAME = aws_db_instance.db.address
          PGSQL_USERNAME = aws_db_instance.db.username
          REDIS_HOSTNAME = aws_elasticache_serverless_cache.cache.endpoint[0].address
          REDIS_PORT = aws_elasticache_serverless_cache.cache.endpoint[0].port
        }
      }
    }
    auto_deployments_enabled = true
  }

  network_configuration {
    ingress_configuration {
      is_publicly_accessible = true
    }
    egress_configuration {
      egress_type = "VPC"
      vpc_connector_arn = aws_apprunner_vpc_connector.apprunner_vpc.arn
    }
  }

  health_check_configuration {
    path = "/actuator/health"
    protocol = "HTTP"
  }

  instance_configuration {
    instance_role_arn = aws_iam_role.masterdetails_deploy_role.arn
  }

  tags = {
    Name = local.service_name
  }
}
