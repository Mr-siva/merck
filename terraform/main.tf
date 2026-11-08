data "aws_vpc" "default" {
  default = true
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_key_pair" "this" {
  key_name   = "msd-hello"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

resource "aws_security_group" "web" {
  name        = "msd-hello"
  description = "HTTP from anywhere, SSH from admin_cidr only"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    for_each = var.admin_cidr == "" ? [] : [var.admin_cidr]
    content {
      description = "SSH (admin only)"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "hello" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.this.key_name
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = templatefile("${path.module}/../deploy/cloud-init.yaml.tftpl", {
    server_py   = base64encode(file("${path.module}/../app/server.py"))
    hello_svc   = base64encode(file("${path.module}/../deploy/systemd/hello.service"))
    hc_svc      = base64encode(file("${path.module}/../deploy/systemd/healthcheck.service"))
    hc_timer    = base64encode(file("${path.module}/../deploy/systemd/healthcheck.timer"))
    healthcheck = base64encode(file("${path.module}/../deploy/healthcheck.sh"))
  })
  user_data_replace_on_change = true

  metadata_options {
    http_tokens = "required" # IMDSv2 only
  }

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  tags = { Name = "msd-hello" }
}
