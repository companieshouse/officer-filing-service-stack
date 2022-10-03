locals {
  vpc_id            = data.terraform_remote_state.networks.outputs.vpc_id
  application_ids   = data.terraform_remote_state.networks.outputs.application_ids
  application_cidrs = data.terraform_remote_state.networks.outputs.application_cidrs
  public_ids        = data.terraform_remote_state.networks.outputs.public_ids
  public_cidrs      = data.terraform_remote_state.networks.outputs.public_cidrs
}

locals {
  internal_cidrs = values(data.terraform_remote_state.networks_common_infra.outputs.internal_cidrs)
  vpn_cidrs      = values(data.terraform_remote_state.networks_common_infra.outputs.vpn_cidrs)
}

locals {
  management_private_subnet_cidrs = values(data.terraform_remote_state.networks_common_infra_ireland.outputs.management_private_subnet_cidrs)
}

locals {
  # stack name is hardcoded here in main.tf for this stack. It should not be overridden per env
  stack_name       = "payments-service"
  stack_fullname   = "${local.stack_name}-stack"
  name_prefix      = "${local.stack_name}-${var.environment}"

  public_lb_cidrs  = ["0.0.0.0/0"]
  lb_subnet_ids    = "${var.admin_lb_internal ? local.application_ids : local.public_ids}" # place ALB in correct subnets
  lb_access_cidrs  = "${var.admin_lb_internal ?
                      concat(local.internal_cidrs,local.vpn_cidrs,local.management_private_subnet_cidrs,split(",",local.application_cidrs)) :
                      local.public_lb_cidrs }"
  app_access_cidrs = "${var.admin_lb_internal ?
                      concat(local.internal_cidrs,local.vpn_cidrs,local.management_private_subnet_cidrs,split(",",local.application_cidrs)) :
                      concat(local.internal_cidrs,local.vpn_cidrs,local.management_private_subnet_cidrs,split(",",local.application_cidrs),split(",",local.public_cidrs)) }"
}