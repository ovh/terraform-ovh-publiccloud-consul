variable "image_id" {
  description = "The ID of the glance image to run in the cluster. If `post_install_module` is set to `false`, this should be an image built from the Packer template under examples/consul-glance-image/consul.json. If the default value is used, Terraform will look up the latest image build automatically."
  default     = ""
}

variable "image_name" {
  description = "The name of the glance image to run in the cluster. If `post_install_module` is set to `false`, this should be an image built from the Packer template under examples/consul-glance-image/consul.json. If the default value is used, Terraform will look up the latest image build automatically."
  default     = "CoreOS Stable"
}

variable "flavor_name" {
  description = "The flavor name that will be used for consul nodes."
  default     = "s1-4"
}

variable "region" {
  description = "The OVH region to deploy into (e.g. GRA3, BHS3, ...)."
}

variable "name" {
  description = "What to name the Consul cluster and all of its associated resources."
}

variable "count" {
  description = "The number of Consul server nodes to deploy. We strongly recommend using 3 or 5."
  default     = 3
}

variable "cidr" {
  description = "The CIDR block of the Network. (e.g. 10.0.0.0/16)"
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
  description = "Optional ca certificate to add to the nodes. If `cfssl` is set to `true`, cfssl will use `cacert` along with `cakey` to generate certificates. Otherwise will generate a new self signed ca."
  default     = ""
}

variable "cacert_key" {
  description = "Optional ca certificate key. If `cfssl` is set to `true`, cfssl will use `cacert` along with `cakey` to generate certificates. Otherwise will generate a new self signed ca."
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

variable "post_install_modules" {
  description = "Setting this variable to true will assume the necessary software to boot the cluster hasn't packaged in the image and thus will be post provisionned. Defaults to `false`"
  default     = true
}

variable "provision_remote_exec" {
  type        = "list"
  description = "List of inline remote commands to execute on post provisionning phase"
  default     = []
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
  description = "Set to true if os family supports ignition, such as CoreOS/Container Linux distribution"
  default     = true
}

variable "consul_version" {
  description = "The version of consul to install with the post installation script if `post_install_module` is set to true"
  default     = "1.0.2"
}

variable "consul_sha256sum" {
  description = "The sha256 checksum of the consul binary to install with the post installation script if `post_install_module` is set to true"
  default     = "418329f0f4fc3f18ef08674537b576e57df3f3026f258794b4b4b611beae6c9b"
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
    UK1  = "eu"
  }
}

variable "default_ip_dns_domains" {
  description = "Default value for `ip_dns_domains`"
  default     = "net"
}

variable "cfssl" {
  description = <<DESC
Defines if cfssl shall be started and used as a pki. If set to `true`
and no cacert with associated private key is given as argument, cfssl will
generate its own self signed ca cert.

The cfssl server is started on the first cluster node.
If started, consul agents watches for the cfssl service,
and each agent gets its own tls keypair and restart.

At every consul agent restart, if tls keypair is older than 1h,
a new keypair will be fetched.

Additionally, the CA generated by cfssl if no cacert is given as argument,
will we publicly available on "kv/cacerts/". Any CA under this key prefix
will be installed on systems hosting a consul agent.
(note: works only on container linux)
DESC

  default     = false
}
