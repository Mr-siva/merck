variable "region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  description = "Must be free-tier eligible in your account (t3.micro in us-east-1)."
  type        = string
  default     = "t3.micro"
}

variable "admin_cidr" {
  description = "CIDR allowed to SSH (e.g. 203.0.113.4/32). Empty string disables SSH entirely."
  type        = string
  default     = ""

  validation {
    condition     = var.admin_cidr != "0.0.0.0/0"
    error_message = "Refusing to open SSH to the whole internet."
  }
}

variable "ssh_public_key_path" {
  description = "Path to the public key installed on the instance."
  type        = string
  default     = "~/.ssh/msd_key.pub"
}
