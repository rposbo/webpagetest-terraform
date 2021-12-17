# Configuration settings

## Setting up the AWS Terraform provider
## ADD YOUR TERRAFORM AWS IAM USER DETAILS IN
## YOUR .aws PROFILE FILE OR AS ENVIRONMENT VARIABLES
provider "aws" {
  region    = "${var.region}"
  profile   = "terraform"
  default_tags {
    tags = {
      Name      = "WebPageTest ${formatdate("YYYY",timestamp())}"
      Project   = "webperf"
      Version   = formatdate("YYYY MM",timestamp())
      TimeStamp = formatdate("YYYY-MM-DD hh.mm",timestamp())
    }
  }
}