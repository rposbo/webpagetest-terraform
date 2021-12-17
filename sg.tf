# Security group for the WebPageTest server
## Incoming HTTP is wide open; for this version it's necessary
## as the WPT agents need to poll for work

## Limit incoming SSH to the IP address you passed in 
## using the "my_ip" variable

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