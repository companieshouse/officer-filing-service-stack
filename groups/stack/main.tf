provider "aws" {
  region  = var.aws_region
  version = "~> 2.32.0"
}

terraform {
  backend "s3" {
  }
}

provider "vault" {
  auth_login {
    path = "auth/userpass/login/${var.vault_username}"
    parameters = {
      password = var.vault_password
    }
  }
}

module "ecs-cluster" {
  source = "git::git@github.com:companieshouse/terraform-library-ecs-cluster.git?ref=1.1.3"

  stack_name                 = local.stack_name
  name_prefix                = local.name_prefix
  environment                = var.environment
  vpc_id                     = local.vpc_id
  subnet_ids                 = local.application_ids
  ec2_key_pair_name          = var.ec2_key_pair_name
  ec2_instance_type          = var.ec2_instance_type
  ec2_image_id               = var.ec2_image_id
  asg_max_instance_count     = var.asg_max_instance_count
  asg_min_instance_count     = var.asg_min_instance_count
  asg_desired_instance_count = var.asg_desired_instance_count
}

module "secrets" {
  source = "./module-secrets"

  stack_name  = local.stack_name
  name_prefix = local.name_prefix
  environment = var.environment
  kms_key_id  = data.terraform_remote_state.services-stack-configs.outputs.services_stack_configs_kms_key_id
  secrets     = data.vault_generic_secret.secrets.data
}

module "ecs-stack" {
  source = "./module-ecs-stack"

  stack_name                 = local.stack_name
  name_prefix                = local.name_prefix
  environment                = var.environment
  vpc_id                     = local.vpc_id
  ssl_certificate_id         = var.ssl_certificate_id
  zone_id                    = var.zone_id
  external_top_level_domain  = var.external_top_level_domain
  internal_top_level_domain  = var.internal_top_level_domain
  subnet_ids                 = local.lb_subnet_ids
  web_access_cidrs           = local.lb_access_cidrs
  admin_lb_internal          = var.admin_lb_internal
}

module "ecs-services" {
  source = "./module-ecs-services"

  name_prefix               = local.name_prefix
  environment               = var.environment
  officer-filing-api-lb-arn = module.ecs-stack.officer-filing-api-lb-listener-arn
  officer-filing-api-lb-listener-arn = module.ecs-stack.officer-filing-api-lb-listener-arn
  vpc_id                    = local.vpc_id
  subnet_ids                = local.application_ids
  web_access_cidrs          = local.app_access_cidrs
  aws_region                = var.aws_region
  ssl_certificate_id        = var.ssl_certificate_id
  external_top_level_domain = var.external_top_level_domain
  internal_top_level_domain = var.internal_top_level_domain
  account_subdomain_prefix  = var.account_subdomain_prefix
  ecs_cluster_id            = module.ecs-cluster.ecs_cluster_id
  task_execution_role_arn   = module.ecs-cluster.ecs_task_execution_role_arn
  docker_registry           = var.docker_registry
  secrets_arn_map           = module.secrets.secrets_arn_map
  log_level                 = var.log_level
  cookie_domain             = var.cookie_domain
  cookie_name               = var.cookie_name

  # eric specific configs
  eric_version                   = var.eric_version
  eric_cache_url                 = var.eric_cache_url
  eric_cache_max_connections     = var.eric_cache_max_connections
  eric_cache_max_idle            = var.eric_cache_max_idle
  eric_cache_idle_timeout        = var.eric_cache_idle_timeout
  eric_cache_ttl                 = var.eric_cache_ttl
  eric_flush_interval            = var.eric_flush_interval
  eric_graceful_shutdown_period  = var.eric_graceful_shutdown_period
  eric_default_rate_limit        = var.eric_default_rate_limit
  eric_default_rate_limit_window = var.eric_default_rate_limit_window

  # api configs
  internal_api_url                   = var.internal_api_url
  api_url                            = var.api_url

  # payments-admin-web variables
  officer_filing_api_release_version  = var.officer_filing_api_release_version
  officer_filing_api_application_port = "10000"
  officer_filing_api_url     = var.officer_filing_api_url
  oauth2_redirect_uri        = var.oauth2_redirect_uri
  oauth2_token_uri           = var.oauth2_token_uri
  cdn_host                   = var.cdn_host
  chs_url                    = var.chs_url
  account_url                = var.account_url
  monitor_url                = var.monitor_url
  cache_pool_size            = var.cache_pool_size
  cache_server               = var.cache_server
  default_session_expiration = var.default_session_expiration
  refund_upload_timeout      = var.refund_upload_timeout
}
