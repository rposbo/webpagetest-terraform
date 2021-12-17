## All of these can (and should) be overridden from the command line, e.g.:
## -var region=us-east-1 -var my_ip=123.123.123.123

variable "region" {
  type = string
  default = "eu-west-1"
}

variable "instance_type" {
  type = string
  default = "t2.micro"
}

# Need to pass in your current IP address to open the port up
# so TF can run the installation commands
variable "my_ip" {
  type = string
  description = "Your current IP to add to the security group for SSH, else TF can't execute remote commands"
}

variable "api_key" {
  type = string
  default = ""
  description = "WebPageTest API key - will generate a random one if not specified"
}

variable "crux_api_key" {
  type = string
  default = ""
  description = "Chrome UX API key to pull down CrUX data"
}

variable "keypair" {
    type = string
    description = "Name of the keypair in AWS"
}

variable "keypair_location" {
  type = string
  description = "local location for the pem file of the named keypair"
}
