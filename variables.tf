variable "image_id" {
  description = "The ID of the glance image to run in the cluster. This should be an image built from the Packer template under examples/consul-glance-image/consul.json. If the default value is used, Terraform will look up the latest image build automatically."
  default     = ""
}

variable "image_names" {
  type        = "map"
  description = "The name per region of the consul glance image. This variable can be overriden by the \"image_id\" variable"

  default = {
    GRA1 = "CentOS 7 Consul"
    SBG3 = "CentOS 7 Consul"
    GRA3 = "CentOS 7 Consul"
    SBG3 = "CentOS 7 Consul"
    BHS3 = "CentOS 7 Consul"
    WAW1 = "CentOS 7 Consul"
    DE1  = "CentOS 7 Consul"
  }
}

variable "flavor_names" {
  type = "map"

  description = "A map of flavor names per openstack region that will be used for consul servers."

  default = {
    GRA1 = "s1-4"
    SBG3 = "s1-4"
    GRA3 = "s1-4"
    SBG3 = "s1-4"
    BHS3 = "s1-4"
    WAW1 = "s1-4"
    DE1  = "s1-4"
  }
}

variable "region" {
  description = "The OVH region to deploy into (e.g. GRA3, BHS3, ...)."
  default     = "GRA3"
}

variable "name" {
  description = "What to name the Consul cluster and all of its associated resources."
  default     = "mycluster"
}

variable "count" {
  description = "The number of Consul server nodes to deploy. We strongly recommend using 3 or 5."
  default     = 3
}

variable "cidr" {
  description = "The CIDR block of the Network. (e.g. 10.0.0.0/16)"
}

variable "network_id" {
  description = "The id of the network in which the servers will be spawned."
}

variable "subnet_id" {
  description = "The id of the subnet in which the servers will be spawned."
}

variable "additional_filepaths" {
  description = "List of additional file path to add on the server nodes. Useful to set additional configuration files for consul."
  default     = []
}

variable "additional_filecontents" {
  description = "List of additional file contents to add on the server nodes. Will be written accordingly with the \"additional_filepaths\" variable."
  default     = []
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
  description = "An optional list of IPv4 of a consul server nodes to join."
  default     = []
}

variable "join_ipv4_addr_wan" {
  description = "An optional list of IPv4 of a consul server nodes from a different DC to join."
  default     = []
}

variable "agent_tags" {
  description = "An optional list of tags to set on the consul agents."
  default     = []
}

variable "cluster_tag_key" {
  description = "The tag the instances will look for to automatically discover each other and form a cluster."
  default     = "consul-servers"
}

variable "cluster_tag_value" {
  description = "The tag value the instances will filter for to automatically discover each other and form a cluster."
}

variable "ssh_key_pair" {
  description = "The name of an  key pair that can be used to SSH to the instances in this cluster. Set to an empty string to not associate a Key Pair."
  default     = ""
}

variable "metadata" {
  description = "A map of metadata to add to all resources supporting it."
  default     = {}
}
