# The results of these will be displayed on the command line

## URL for your WebPageTest instance
output "public_dns" {
  value = "${aws_instance.webpagetest.public_dns}"
}

## Public IP for your WebPageTest instance
output "public_ip" {
  value = "${aws_instance.webpagetest.public_ip}"
}

## Generated API key so you can orchestrate your WPT test via API
output "api_key" {
  value = "${local.api_key}"
}