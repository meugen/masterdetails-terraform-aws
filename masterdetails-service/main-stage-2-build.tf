resource "aws_ecr_repository" "repo" {
  name                 = var.github_repo
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  tags = {
    Service = "masterdetails"
  }
}

data "aws_codestarconnections_connection" "connection" {
  name = var.github_conn
}

resource "aws_cloudwatch_log_group" "log_group" {
  name = local.log_group
}

resource "aws_cloudwatch_log_stream" "log_stream" {
  log_group_name = aws_cloudwatch_log_group.log_group.name
  name           = local.log_stream
}

data "aws_iam_policy_document" "assume_build_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "masterdetails_build_role" {
  name               = local.build_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_build_role.json
}

data "aws_iam_policy_document" "masterdetails_build_role" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      aws_cloudwatch_log_group.log_group.arn,
      aws_cloudwatch_log_stream.log_stream.arn,
      "${aws_cloudwatch_log_group.log_group.arn}/*",
      "${aws_cloudwatch_log_stream.log_stream.arn}/*"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken",
      "secretsmanager:GetSecretValue"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:BatchCheckLayerAvailability"
    ]

    resources = [
      aws_ecr_repository.repo.arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "codeconnections:GetConnection",
      "codeconnections:GetConnectionToken"
    ]

    resources = [
      data.aws_codestarconnections_connection.connection.arn
    ]
  }
}

resource "aws_iam_role_policy" "masterdetails_build_policy" {
  role   = aws_iam_role.masterdetails_build_role.name
  policy = data.aws_iam_policy_document.masterdetails_build_role.json
}

resource "time_sleep" "build_wait_10s" {
  depends_on      = [aws_iam_role_policy.masterdetails_build_policy]
  create_duration = "10s"
}

resource "aws_codebuild_project" "project" {
  depends_on = [time_sleep.build_wait_10s]

  name         = local.project_name
  service_role = aws_iam_role.masterdetails_build_role.arn

  source {
    type     = "GITHUB"
    location = "https://github.com/${var.github_repo}"
    buildspec = templatefile("${path.module}/buildspec.yml.tftpl", {
      region             = var.region,
      registry_id        = aws_ecr_repository.repo.registry_id,
      repository_url     = aws_ecr_repository.repo.repository_url,
      docker_io_username = var.docker_io_username
      docker_io_secret   = var.docker_io_secret
    })

    auth {
      type     = "CODECONNECTIONS"
      resource = data.aws_codestarconnections_connection.connection.arn
    }
  }
  source_version = var.github_branch

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_MEDIUM"
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type         = "LINUX_CONTAINER"
  }

  logs_config {
    cloudwatch_logs {
      status      = "ENABLED"
      group_name  = aws_cloudwatch_log_group.log_group.name
      stream_name = aws_cloudwatch_log_stream.log_stream.name
    }
    s3_logs {
      status = "DISABLED"
    }
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE"]
  }
}

action "aws_codebuild_start_build" "build" {
  config {
    project_name   = aws_codebuild_project.project.name
    source_version = var.github_branch
  }
}

resource "terraform_data" "build_trigger" {
  depends_on = [aws_codebuild_project.project]

  lifecycle {
    action_trigger {
      events  = [after_create]
      actions = [action.aws_codebuild_start_build.build]
    }
  }
}
