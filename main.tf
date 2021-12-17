# API key as a random 40 char string
resource "random_string" "api-key" {
  length = 40
  special = false
}

# define a local "api_key" variable
locals {
  api_key = length(var.api_key) > 0 ? var.api_key : "${random_string.api-key.result}"
}

# Create a random 10 character string to hopefully create 
# a unique S3 bucket for the WPT tests to be archived to
resource "random_string" "bucket" {
  length = 10
  special = false
  upper = false
}

