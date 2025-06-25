variable "aws_region" {
  description = "The AWS region where resources will be created"
  type        = string
  default     = "ap-south-1"
}

variable "enable_vpn" {
  description = "Enable VPN connection for branch office"
  type        = bool
  default     = true
}

variable "bi_vpn" {
  description = "Enable bi-directional VPN connection for branch office"
  type        = bool
  default     = false
}