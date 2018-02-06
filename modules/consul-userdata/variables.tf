variable "count" {
  description = "Specifies the number of nodes in the cluster"
  default     = 1
}

variable "ignition_mode" {
  description = "Defines if main output is in ignition or cloudinit format"
  default     = true
}

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

variable "cacert_key" {
  description = "Optional ca certificate to use in conjunction with `cacert` for generating certs with cfssl."
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

variable "cfssl" {
  description = "Defines if cfssl shall be started and used a pki. If no cacert with associated private key is given as argument, cfssl will generate its own self signed ca cert."
  default     = false
}

variable "cfssl_ca_validity_period" {
  description = "validity period for generated CA"
  default     = "43800h"
}

variable "cfssl_cert_validity_period" {
  description = "default validity period for generated certs"
  default     = "8760h"
}

variable "cfssl_cn" {
  description = "generated certs common name field "
  default     = ""
}

variable "cfssl_c" {
  description = "generated certs country field"
  default     = ""
}

variable "cfssl_l" {
  description = "generated certs location field"
  default     = "Roubaix"
}

variable "cfssl_o" {
  description = "generated certs org field"
  default     = "myorg"
}

variable "cfssl_ou" {
  description = "generated certs ou field"
  default     = "59"
}

variable "cfssl_st" {
  description = "generated certs state field"
  default     = "Nord"
}

variable "cfssl_key_algo" {
  description = "generated certs key algo"
  default     = "rsa"
}

variable "cfssl_key_size" {
  description = "generated certs key size"
  default     = "2048"
}

variable "cfssl_bind" {
  description = "cfssl service bind addr"
  default     = "0.0.0.0"
}

variable "cfssl_port" {
  description = "cfssl service bind port"
  default     = "8888"
}
