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
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "3.0.0"  # Use a specific version of the module for version pinning

  name = "dev"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

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
  version = "5.1.0"  # Use a specific version of the module for version pinning

  name    = "blog"

  vpc_id  = module.vpc.vpc_id  # Use the VPC ID from the created VPC module

  ingress_rules = [
    {
      description      = "Allow HTTP inbound traffic"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    },
    {
      description      = "Allow HTTPS inbound traffic"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    },
  ]

  # For egress rules, it's not necessary to explicitly allow all traffic (all-all), 
  # as all outbound traffic is allowed by default. We can omit the egress_rules and egress_cidr_blocks.
  # If you want to restrict egress traffic, you can explicitly define the egress_rules as needed.
}
