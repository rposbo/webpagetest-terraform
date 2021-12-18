# Using Terraform to define an AutoScaling Private WebPageTest instance in code

This is my attempt at a (hopefully) well structured terraform project for a private WebPageTest setup, installing from a base Ubuntu OS.

You'll need to pass in your current IP address as a Terraform variable, e.g.

`terraform apply -var my_ip=<your IP here>`

1. Get an [AWS account](https://aws.amazon.com/).
2. Go get [Terraform](https://www.terraform.io/downloads.html).
3. Grab this repo.
4. Read [this article](https://www.robinosborne.co.uk/?p=2754) and also [this more recent article](https://www.robinosborne.co.uk/?p=3052).
5. Run `terraform apply` (you can pass in the variables instead with `terraform apply -var 'keypair=MINE' -var 'region=us-east-1'`, for example)
6. Your very own private, autoscaling, WebPageTest!

> If you want to refer to the exact code used in my "[Automate Your WebPageTest Private Instance With Terraform: 2021 Edition](https://www.robinosborne.co.uk/?p=3052)" article, look in the "blog-post-reference" folder!
