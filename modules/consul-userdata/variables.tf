variable "agent_mode" {
  description = "The agent mode of the consul nodes. Can be either `server` or `client`"
  default     = "server"
}

variable "agent_tags" {
  description = "An optional list of tags to set on the consul agents."
  default     = []
}

variable "additional_filepaths" {
  description = "List of additional file path to add on the server nodes. Useful to set additional configuration files for consul."
  default     = []
}

variable "additional_filecontents" {
  description = "List of additional file contents to add on the server nodes. Will be written accordingly with the \"additional_filepaths\" variable."
  default     = []
}

variable "additional_units" {
  description = "List of additional systemd unit to add on the server nodes. Useful to customize nodes, e.g. starting a fabio lb."
  default     = []
}

variable "additional_unitcontents" {
  description = "List of additional systemd units contents to add on the server nodes. Will be written accordingly with the \"additional_filepaths\" variable."
  default     = []
}

variable "ssh_public_keys" {
  type        = "list"
  description = "The ssh public keys that can be used to SSH to the instances in this cluster."
  default     = []
}

variable "cidr_blocks" {
  type        = "list"
  description = "The CIDR blocks of the Network. (e.g. 10.0.0.0/16)"
}

variable "cacert" {
  description = "Optional ca certificate to add to the server nodes."
  default     = ""
}

variable "domain" {
  description = "The domain of the consul cluster."
  default     = "consul"
}

variable "datacenter" {
  description = "The datacenter of the consul cluster."
  default     = "dc1"
}

variable "join_ipv4_addr" {
  type        = "list"
  description = "The list of IPv4 of a consul server nodes to join."
  default     = []
}

variable "join_ipv4_addr_wan" {
  type        = "list"
  description = "An optional list of IPv4 of a consul server nodes from a different DC to join."
  default     = []
}

variable "bootstrap_expect" {
  description = "The expect number of consul servers to achieve bootstrap phase"
  default     = 1
}

variable "public_facing" {
  description = "Determines if the node is internet public facing, meaning it has an interface with an internet public ipv4. Interface must be eth1 for internet traffic. eth0 is reserved for private traffic."
  default     = false
}
