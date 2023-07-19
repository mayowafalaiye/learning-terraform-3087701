# Define data block to retrieve the latest AWS AMI based on specified filters
data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["979382823631"] # Bitnami
}

# Create an AWS VPC using the "terraform-aws-modules/vpc/aws" module
module "aws_default_vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "X.Y.Z"  # Replace with a version that supports enable_classiclink

  name = "dev"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_classiclink = true  # Use the appropriate value for your use case

  enable_nat_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}



# Launch an AWS EC2 instance using the specified AMI and instance type
resource "aws_instance" "blog" {
  ami           = data.aws_ami.app_ami.id
  instance_type = var.instance_type

  vpc_security_group_ids  = [module.blog_sg.security_group_id]

  tags = {
    Name = "HelloWorld"
  }
}

# Create an AWS security group using the "terraform-aws-modules/security-group/aws" module
module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name    = "blog"
  vpc_id  = module.vpc.vpc_id

  ingress_rules = [
    "tcp,80,80,0.0.0.0/0",
    "tcp,443,443,0.0.0.0/0",
  ]

  # Omit the egress_rules and egress_cidr_blocks, as outbound traffic is allowed by default.
}
