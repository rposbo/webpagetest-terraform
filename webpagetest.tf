# Setting up the AWS Terraform provider
# ADD YOUR TERRAFORM IAM USER DETAILS IN HERE
# OR IN YOUR .aws PROFILE FILE
# OR AS ENVIRONMENT VARIABLES
provider "aws" {
  region = "${var.region}"
  profile       = "terraform"
}

variable "region" {
  default = "eu-west-1"
}

# FILL IN YOUR KEYPAIR NAME HERE:
variable "keypair" {
    default = "wpt"
}

# IAM config
resource "aws_iam_user" "wpt-user" {
  name = "wpt-user"
}

resource "aws_iam_user_policy_attachment" "ec2-policy-attach" {
  user = "${aws_iam_user.wpt-user.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_user_policy_attachment" "s3-policy-attach" {
  user = "${aws_iam_user.wpt-user.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_access_key" "wpt-user" {
  user = "${aws_iam_user.wpt-user.name}"
}

# S3 Config
resource "random_string" "bucket" {
  length = 10
  special = false
  upper = false
}

resource "aws_s3_bucket" "wpt-archive" {
  bucket = "my-wpt-test-archive-${random_string.bucket.result}"
  acl    = "private"
}

# Main EC2 config
resource "aws_instance" "webpagetest" {
  ami = "${lookup(var.wpt_ami, var.region)}"
  instance_type = "t2.micro"
  vpc_security_group_ids  = ["${aws_security_group.wpt-sg.id}"]
  
  # FILL IN THIS PLACEHOLDER:
  key_name  = "${var.keypair}"
  
  user_data     = "${data.template_file.ec2_wpt_userdata.rendered}"
  tags {
   Name      =   "webpagetest"
   Project   =   "webperf"
  }
}

# API key as a random 40 char string
resource "random_string" "api-key" {
  length = 40
  special = false
}

# define a local "api_key" variable
locals {
  "api_key" = "${random_string.api-key.result}"
}

data "template_file" "ec2_wpt_userdata" {
    template =<<EOT
      ec2_key=$${key}
      ec2_secret=$${secret}
      api_key=$${api_key}
      waterfall_show_user_timing=1
      iq=75
      pngss=1
      archive_s3_server=s3.amazonaws.com
      archive_s3_key=$${key}
      archive_s3_secret=$${secret}
      archive_s3_bucket=$${wpt_s3_archive}
      archive_days=1
      cron_archive=1
    EOT

    vars = {
        key = "${aws_iam_access_key.wpt-user.id}"
        secret = "${aws_iam_access_key.wpt-user.secret}"
        api_key = "${local.api_key}"
        wpt_s3_archive = "${aws_s3_bucket.wpt-archive.bucket}"
    }
}

# Security group for the WebPageTest server
resource "aws_security_group" "wpt-sg" {
  name = "wpt-sg"

  # http  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "HTTP"
    cidr_blocks = ["0.0.0.0/0"]
  }  
  
  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    description = "SSH"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# WebPageTest EC2 AMIs
variable "wpt_ami" {
    type    = "map"
    default = {
        us-east-1 = "ami-fcfd6194"
        us-west-1= "ami-e44853a1"
        us-west-2= "ami-d7bde6e7"
        sa-east-1= "ami-0fce7112"
        eu-west-1= "ami-9978f6ee"
        eu-central-1= "ami-22cefd3f"
        ap-southeast-1 = "ami-88bd97da"
        ap-southeast-2 = "ami-eb3542d1"
        ap-northeast-1 = "ami-66233967"
    }
}

# Get the resulting URL for your WebPageTest instance
output "webpagetest" {
  value = "${aws_instance.webpagetest.public_dns}"
}

# Get the generated API key so you can orchestrate your WPT test
output "api_key" {
  value = "${local.api_key}"
}