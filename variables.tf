variable "image_id" {
  description = "The ID of the glance image to run in the cluster. If `post_install_module` is set to `false`, this should be an image built from the Packer template under examples/consul-glance-image/consul.json. If the default value is used, Terraform will look up the latest image build automatically."
  default     = ""
}

variable "image_name" {
  description = "The name of the glance image to run in the cluster. If `post_install_module` is set to `false`, this should be an image built from the Packer template under examples/consul-glance-image/consul.json. If the default value is used, Terraform will look up the latest image build automatically."
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

variable "public_network_id" {
  description = "The network_id is not yet accessible through the openstack subnet datasource but it will soon be released. Meanwhile this attribute must be set. It will become deprecated as soon as the openstack provider is released."
  default = ""
}

variable "network_id" {
  description = "The network_id is not yet accessible through the openstack subnet datasource but it will soon be released. Meanwhile this attribute must be set. It will become deprecated and optional as soon as the openstack provider is released."
}

variable "subnet_ids" {
  type = "list"

  description = <<DESC
The list of subnets ids to deploy consul nodes in.
If `count` is specified, will spawn `count` consul node
accross the list of subnets. Conflicts with `subnets`.
DESC

  default = []
}

variable "subnets" {
  type = "list"

  description = <<DESC
The list of subnets CIDR blocks to deploy consul nodes in.
If `count` is specified, will spawn `count` consul node
accross the list of subnets. Conflicts with `subnet_ids`.
DESC

  default = [""]
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

variable "security_group_ids" {
  type        = "list"
  description = "An optional list of additional security groups to attach to private ports"
  default     = []
}

variable "public_security_group_ids" {
  type        = "list"
  description = "An optional list of additional security groups to attach to public ports"
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

variable "ssh_public_keys" {
  type        = "list"
  description = "The ssh public keys that can be used to SSH to the instances in this cluster."
  default     = []
}

variable "agent_mode" {
  description = "The agent mode of the consul nodes. Can be either `server` or `client`"
  default     = "server"
}

variable "metadata" {
  description = "A map of metadata to add to all resources supporting it."
  default     = {}
}

variable "post_install_module" {
  description = "Setting this variable to true will assume the necessary software to boot the cluster hasn't packaged in the image and thus will be post provisionned. Defaults to `false`"
  default     = false
}

variable "ssh_user" {
  description = "The ssh username of the image used to boot the consul cluster."
  default     = "core"
}

variable "ssh_private_key" {
  description = "The ssh private key used to post provision the consul cluster. This is required if `post_install_module` is set to `true`. It must be set accordingly to `ssh_key_pair"
  default     = ""
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

variable "ignition_mode" {
  description = "Set to true if os family supports ignition, such as CoreOS distribution"
  default     = false
}

variable "consul_version" {
  description = "The version of consul to install with the post installation script if `post_install_module` is set to true"
  default     = "1.0.1"
}

variable "consul_sha256sum" {
  description = "The sha256 checksum of the consul binary to install with the post installation script if `post_install_module` is set to true"
  default     = "eac5755a1d19e4b93f6ce30caaf7b3bd8add4557b143890b1c07f5614a667a68"
}

variable "fabio_version" {
  description = "The version of fabio to install with the post installation script if `post_install_module` is set to true"
  default     = "1.5.3"
}

variable "fabio_sha256sum" {
  description = "The sha256 checksum of the fabio binary to install with the post installation script if `post_install_module` is set to true"
  default     = "ad352a3e770215219c57257c5dcbb14aee83aa50db32ba34431372b570aa58e5"
}

variable "associate_public_ipv4" {
  description = "Associate a public ipv4 with the consul nodes"
  default     = false
}

variable "ip_dns_domains" {
  description = "Every public ipv4 addr at OVH is registered as a A record in DNS zones according to the format ip 1.2.3.4 > ip4.ip-q1-2-3.eu for EU regions or  ip4.ip-1-2-3.net for other ones. This variables maps the domain name to use according to the region."
  default = {
    GRA1 = "eu"
    SBG3 = "eu"
    GRA3 = "eu"
    SBG3 = "eu"
    BHS3 = "net"
    WAW1 = "eu"
    DE1  = "eu"
  }
}
