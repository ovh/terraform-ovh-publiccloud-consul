variable "count" {
  description = "The number of resource to post provision"
  default     = 1
}

variable "ipv4_addrs" {
  type        = "list"
  description = "The list of IPv4 addrs to provision"
}

variable "triggers" {
  type        = "list"
  description = "The list of values which can trigger a provisionning"
}

variable "ssh_user" {
  description = "The ssh username of the image used to boot the consul cluster."
  default     = "core"
}

variable "ssh_private_key" {
  description = "The ssh private key used to post provision the consul cluster. This is required if `post_install_module` is set to `true`. It must be set accordingly to `ssh_key_pair"
}

variable "ssh_bastion_host" {
  description = "The address of the bastion host used to post provision the consul cluster. This may be required if `post_install_module` is set to `true`"
  default     = ""
}

variable "ssh_bastion_user" {
  description = "The ssh username of the bastion host used to post provision the consul cluster. This may be required if `post_install_module` is set to `true`"
  default     = ""
}

variable "ssh_bastion_private_key" {
  description = "The ssh private key of the bastion host used to post provision the consul cluster. This may be required if `post_install_module` is set to `true`"
  default     = ""
}

variable "cfssl_version" {
  description = "The version of cfssl to install with the post installation script if `post_install_module` is set to true"
  default     = "R1.2"
}

variable "cfssl_sha256sum" {
  description = "The sha256 checksum of the cfssl binary to install with the post installation script if `post_install_module` is set to true"
  default     = "eb34ab2179e0b67c29fd55f52422a94fe751527b06a403a79325fed7cf0145bd"
}
