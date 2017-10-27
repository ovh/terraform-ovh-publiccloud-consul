## DEPLOY A CONSUL CLUSTER IN OVH
## These templates show an example of how to use the consul-cluster
## module to deploy Consul in OVH. ## We deploy two Server
## Groups: one with a small number of Consul server nodes and one
## with a larger number of Consul client nodes. Note that these
## templates assume that the Glance Image you provide via the
## image_id input variable is built from the
## examples/consul-glance-image/consul.json Packer template.
provider "openstack" {
  alias  = "${var.region}"
  region = "${var.region}"
}

# AUTOMATICALLY LOOK UP THE LATEST PRE-BUILT GLANCE IMAGE
# !! WARNING !! These exmaple Glance Images are meant only convenience when initially testing this repo. Do NOT use these example images in a production setting because it is important that you consciously think through the configuration you want in your own production image.
#
# NOTE: This Terraform data source must return at least one Image result or the entire template will fail.
data "openstack_images_image_v2" "consul" {
  provider    = "openstack.${var.region}"
  count       = "${var.image_id == "" ? 1 : 0}"
  name        = "${lookup(var.image_names, var.region)}"
  most_recent = true
}

resource "openstack_networking_secgroup_v2" "servers_sg" {
  provider = "openstack.${var.region}"

  name        = "${var.name}_servers_sg"
  description = "${var.name} security group for consul server hosts"
}

resource "openstack_networking_secgroup_rule_v2" "in_traffic_tcp" {
  provider = "openstack.${var.region}"
  count    = "${var.count > 0 ? 1  : 0 }"

  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  remote_ip_prefix  = "${var.cidr}"
  security_group_id = "${openstack_networking_secgroup_v2.servers_sg.id}"
}

resource "openstack_networking_secgroup_rule_v2" "in_traffic_udp" {
  provider = "openstack.${var.region}"
  count    = "${var.count > 0 ? 1  : 0 }"

  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  remote_ip_prefix  = "${var.cidr}"
  security_group_id = "${openstack_networking_secgroup_v2.servers_sg.id}"
}

resource "openstack_networking_port_v2" "port_consul" {
  provider = "openstack.${var.region}"
  count    = "${var.count}"

  name               = "${var.name}_consul_server_port_${count.index}"
  network_id         = "${var.network_id}"
  admin_state_up     = "true"
  security_group_ids = ["${openstack_networking_secgroup_v2.servers_sg.id}"]

  fixed_ip {
    subnet_id = "${var.subnet_id}"
  }
}

resource "openstack_compute_servergroup_v2" "consul" {
  provider = "openstack.${var.region}"
  name     = "${var.name}-consul-servers-servergroup"
  policies = ["anti-affinity"]
}

data "template_file" "additional_files" {
  count = "${length(var.additional_filepaths)}"

  template = <<TPL
- path: $${path}
  content: |
     $${content}
TPL

  vars {
    path    = "${var.additional_filepaths[count.index]}"
    content = "${indent(5, var.additional_filecontents[count.index])}"
  }
}

# Render a multi-part cloudinit config making use of the part
# above, and other source files
data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"

    content = <<CLOUDCONFIG
#cloud-config
## This route has to be added in order to reach other subnets of the network
bootcmd:
    - ip route add ${var.cidr} dev eth0 scope link metric 0
ca-certs:
    trusted:
       - ${var.cacert}
write_files:
  ${indent(2, join("\n", data.template_file.additional_files.*.rendered))}
  - path: /etc/sysconfig/consul.conf
    content: |
      DOMAIN=${var.domain}
      DATACENTER=${var.datacenter}
      CONSUL_MODE=server
      CONSUL_BOOTSTRAP_EXPECT=${var.count}
      PRIVATE_NETWORK=${var.cidr}
      JOIN_IPV4_ADDR=${join(",", coalescelist(var.join_ipv4_addr, flatten(openstack_networking_port_v2.port_consul.*.all_fixed_ips)))}
      JOIN_IPV4_ADDR_WAN=${join(",", var.join_ipv4_addr_wan)}
      CONSUL_AGENT_TAGS=${join(",", var.agent_tags)}
  - path: /etc/sysconfig/network-scripts/route-eth0
    content: |
      ${var.cidr} dev eth0 scope link metric 0
CLOUDCONFIG
  }
}

resource "openstack_compute_instance_v2" "consul" {
  provider = "openstack.${var.region}"
  count    = "${var.count}"
  name     = "${var.name}_consul_server_${count.index}"
  image_id = "${element(coalescelist(data.openstack_images_image_v2.consul.*.id, list(var.image_id)), 0)}"

  flavor_name = "${lookup(var.flavor_names, var.region)}"
  user_data   = "${data.template_cloudinit_config.config.rendered}"
  key_pair    = "${var.ssh_key_pair}"

  network {
    access_network = true
    port           = "${element(openstack_networking_port_v2.port_consul.*.id, count.index)}"
  }

  scheduler_hints {
    group = "${openstack_compute_servergroup_v2.consul.id}"
  }

  # The Openstack Instances will use these tags to automatically discover each other and form a cluster.
  # Note: As of today, this feature isn't used because it would require to give credentials to every instances with full access to the openstack API.
  # the first version of this module will bootstrap a first node that will be used as a "join ip"
  metadata = "${merge(map(var.cluster_tag_key, var.cluster_tag_value), var.metadata)}"
}
