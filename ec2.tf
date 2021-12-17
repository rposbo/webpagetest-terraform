# Main EC2 config
locals {
  keypair_content = file(var.keypair_location)
}

# Get Base OS AMI
data "aws_ami" "webpagetest" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Build WPT Server
resource "aws_instance" "webpagetest" {
  ami = "${data.aws_ami.webpagetest.id}" #"ami-08edbb0e85d6a0a07"
  instance_type = "${var.instance_type}"
  vpc_security_group_ids  = ["${aws_security_group.wpt-sg.id}"]  
  key_name  = "${var.keypair}"

  # Upload and execute installation script from content/ dir
  provisioner "remote-exec" {
    inline = [
      # configure unattended update and upgrades
      "sudo export DEBIAN_FRONTEND=noninteractive",
      "sudo apt-get -yq -o Dpkg::Options::=\"--force-confdef\" -o Dpkg::Options::=\"--force-confold\" update",
      "sudo apt-get -yq -o Dpkg::Options::=\"--force-confdef\" -o Dpkg::Options::=\"--force-confold\" upgrade",
      "sudo apt-get -yq -o Dpkg::Options::=\"--force-confdef\" -o Dpkg::Options::=\"--force-confold\" dist-upgrade",

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
  
  # configure overrides settings.ini file
  provisioner "file" {
    content     = templatefile(
      "content/settings.tpl",
      {
        iam_key = aws_iam_access_key.wpt-user.id
        iam_secret = aws_iam_access_key.wpt-user.secret
        api_key = local.api_key
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
  
  # configure overrides locations.ini file  
  provisioner "file" {
    source = "content/locations.ini"
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
