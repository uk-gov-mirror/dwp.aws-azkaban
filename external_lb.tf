resource "aws_default_route_table" "public" {
  count                = length(data.aws_availability_zones.current.zone_ids)
  default_route_table_id = aws_route_table.workflow_manager_private[count.index].id
  tags                   = merge(local.common_tags, { Name = "${local.name}-azkaban-external-public" })

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_azkaban_external.id
  }
}

resource "aws_internet_gateway" "igw_azkaban_external" {
  vpc_id = module.workflow_manager_vpc.vpc.id
  tags   = merge(local.common_tags, { Name = "${local.name}-azkaban-external-public" })
}

resource "aws_subnet" "external_azkaban" {
  count                = length(data.aws_availability_zones.current.zone_ids)
  cidr_block           = cidrsubnet(local.cidr_block[local.environment].workflow-manager-vpc, var.subnets.public.newbits, var.subnets.public.netnum + count.index)
  vpc_id               = module.workflow_manager_vpc.vpc.id
  availability_zone_id = data.aws_availability_zones.current.zone_ids[count.index]
  tags                 = merge(local.common_tags, { Name = "${local.name}-azkaban-external-public-${data.aws_availability_zones.current.names[count.index]}" })
}

resource "aws_lb" "azkaban_external" {
  name               = "azkaban-external"
  internal           = false
  load_balancer_type = "application"
  subnets            = aws_subnet.external_azkaban.*.id
  security_groups    = [aws_security_group.azkaban_external_loadbalancer.id]
  tags               = merge(local.common_tags, { Name = "${local.name}-azkaban-external-loadbalancer" })
}

resource "aws_lb_listener" "azkaban_external" {
  load_balancer_arn = aws_lb.azkaban_external.arn
  port              = var.external_https_port
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.azkaban_loadbalancer.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.azkaban_external_webserver.arn
  }
}

resource "aws_lb_target_group" "azkaban_external_webserver" {
  name        = "azkaban-external-webserver-http"
  port        = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_external_webserver_port
  protocol    = "HTTPS"
  vpc_id      = module.workflow_manager_vpc.vpc.id
  target_type = "ip"

  health_check {
    protocol = "HTTPS"
    port     = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_external_webserver_port
    path     = "/"
    matcher  = "200"
  }

  stickiness {
    enabled = true
    type    = "lb_cookie"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, { Name = "azkaban-external-webserver" })
}

resource "aws_security_group" "azkaban_external_loadbalancer" {
  vpc_id = module.workflow_manager_vpc.vpc.id
  tags   = merge(local.common_tags, { Name = "${local.name}-azkaban-external-loadbalancer" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_loadbalancer_egress_azkaban_external_webserver" {
  description              = "Allow loadbalancer to access azkaban external webserver user interface"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_external_webserver_port
  to_port                  = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_external_webserver_port
  security_group_id        = aws_security_group.azkaban_external_webserver.id
  source_security_group_id = aws_security_group.azkaban_external_loadbalancer.id
}

resource "aws_security_group_rule" "allow_loadbalancer_ingress_azkaban_external_webserver" {
  description              = "Allow loadbalancer to access azkaban external webserver user interface"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_external_webserver_port
  to_port                  = jsondecode(data.aws_secretsmanager_secret_version.workflow_manager.secret_binary).ports.azkaban_external_webserver_port
  security_group_id        = aws_security_group.azkaban_external_loadbalancer.id
  source_security_group_id = aws_security_group.azkaban_external_webserver.id
}
