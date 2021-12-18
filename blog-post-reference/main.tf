provider "aws" {
  region    = "eu-west-1"
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

locals {
  keypair_content = file("${var.keypair_location}")
}

# random string to aim for a unique bucket name
resource "random_string" "bucket" {
  length = 10
  special = false
  upper = false
}

# S3 bucket for archives
resource "aws_s3_bucket" "wpt-archive" {
  bucket = "my-wpt-test-archive-${random_string.bucket.result}"
  acl    = "private"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  # Canonical
  owners = ["099720109477"] 
}

resource "aws_instance" "wpt" {
    ami = "${data.aws_ami.ubuntu.id}"
    instance_type = "t2.micro"
    key_name  = "wpt"
    vpc_security_group_ids  = ["${aws_security_group.wpt-sg.id}"]

    provisioner "remote-exec" {
        inline = [
        # configure unattended update and upgrades
        "sudo export DEBIAN_FRONTEND=noninteractive",
        "sudo apt -yq -o Dpkg::Options::=\"--force-confdef\" -o Dpkg::Options::=\"--force-confold\" update",
        "sudo apt -yq -o Dpkg::Options::=\"--force-confdef\" -o Dpkg::Options::=\"--force-confold\" upgrade",
        "sudo apt -yq -o Dpkg::Options::=\"--force-confdef\" -o Dpkg::Options::=\"--force-confold\" dist-upgrade",

        # install wpt server
        "wget -O - https://raw.githubusercontent.com/WPO-Foundation/wptserver-install/master/ubuntu.sh | bash"
        ]

        connection {
        host     = "${self.public_ip}"
        type     = "ssh"
        user     = "ubuntu"
        private_key = "${local.keypair_content}"
        }
    }
    
    provisioner "file" {
    content     = templatefile(
      "settings.tpl",
      {
        iam_key = aws_iam_access_key.wpt-user.id
        iam_secret = aws_iam_access_key.wpt-user.secret
        wpt_archive = aws_s3_bucket.wpt-archive.bucket
        crux_api_key = (length(var.crux_api_key)>0 ? "crux_api_key=${var.crux_api_key}" : "")
        agent_tags = join("|", [for k, v in self.tags_all : "${k}=>${v}" if k != "Name"])
      }
    )

    destination = "~/settings.ini"

    connection {
      host     = "${self.public_ip}"
      type     = "ssh"
      user     = "ubuntu"
      private_key = "${local.keypair_content}"
    }
  }

    provisioner "file" {
        source = "locations.ini"
        destination = "~/locations.ini"

    connection {
      host     = "${self.public_ip}"
      type     = "ssh"
      user     = "ubuntu"
      private_key = "${local.keypair_content}"
    }
  }
    
  # move config files to correct place
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /var/www/webpagetest/www/settings/common/",
      "sudo mv ~/*.ini /var/www/webpagetest/www/settings/common/"
    ]

    connection {
      host     = "${self.public_ip}"
      type     = "ssh"
      user     = "ubuntu"
      private_key = "${local.keypair_content}"
    }
  }
}

resource "aws_security_group" "wpt-sg" {
  name = "wpt-sg"

  # incoming http
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "HTTP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ssh
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    description = "SSH"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  # outgoing access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "my_ip" {}

variable "keypair_location" {
  type = string
  description = "location on local disk of your keypair file"
}

variable "crux_api_key" {
  type = string
  default = ""
  description = "Chrome UX API key to pull down CrUX data"
}

resource "aws_iam_user" "wpt-user" {
  name = "wpt-user"
}

resource "aws_iam_access_key" "wpt-user" {
  user = "${aws_iam_user.wpt-user.name}"
}

resource "aws_iam_user_policy_attachment" "ec2-policy-attach" {
  user = "${aws_iam_user.wpt-user.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

output "public_ip" {
  value = "${aws_instance.wpt.public_ip}"
}