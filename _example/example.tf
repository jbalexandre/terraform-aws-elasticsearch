provider "aws" {
  region = "eu-west-1"
}

module "vpc" {
  source = "git::https://github.com/clouddrove/terraform-aws-vpc.git?ref=tags/0.12.1"

  name        = "vpc"
  application = "clouddrove"
  environment = "test"
  label_order = ["environment", "name", "application"]

  cidr_block = "172.16.0.0/16"
}

module "public_subnets" {
  source = "git::https://github.com/clouddrove/terraform-aws-subnet.git?ref=tags/0.12.1"

  name        = "public-subnet"
  application = "clouddrove"
  environment = "test"
  label_order = ["environment", "name", "application"]

  availability_zones = ["eu-west-1b", "eu-west-1c"]
  vpc_id             = module.vpc.vpc_id
  cidr_block         = module.vpc.vpc_cidr_block
  type               = "public"
  igw_id             = module.vpc.igw_id
}

module "security_group" {
  source = "git::https://github.com/clouddrove/terraform-aws-security-group.git?ref=tags/0.12.1"

  name        = "ingress_security_groups"
  application = "clouddrove"
  environment = "test"
  label_order = ["environment", "name", "application"]

  vpc_id        = module.vpc.vpc_id
  allowed_ip    = ["0.0.0.0/0"]
  allowed_ports = [80, 443, 9200]
}

module "elasticsearch" {
  source                         = "git::https://github.com/clouddrove/terraform-aws-elasticsearch.git?ref=tags/0.12.0"
  name                           = "es"
  application                    = "clouddrove"
  environment                    = "test"
  label_order                    = ["environment", "name", "application"]
  domain_name                    = "clouddrove"
  enable_iam_service_linked_role = true
  security_group_ids             = [module.security_group.security_group_ids]
  subnet_ids                     = tolist(module.public_subnets.public_subnet_id)
  zone_awareness_enabled         = true
  elasticsearch_version          = "6.5"
  instance_type                  = "t2.small.elasticsearch"
  instance_count                 = 4
  iam_actions                    = ["es:ESHttpGet", "es:ESHttpPut", "es:ESHttpPost"]
  volume_size                    = 10
  volume_type                    = "gp2"
  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
  }
}