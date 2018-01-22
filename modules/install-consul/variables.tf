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

variable "install_dir" {
  description = "Directory where to install consul"
  default     = "/opt/consul"
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

variable "consul_version" {
  description = "The version of consul to install with the post installation script if `post_install_module` is set to true"
  default     = "1.0.2"
}

variable "consul_sha256sum" {
  description = "The sha256 checksum of the consul binary to install with the post installation script if `post_install_module` is set to true"
  default     = "418329f0f4fc3f18ef08674537b576e57df3f3026f258794b4b4b611beae6c9b"
}
