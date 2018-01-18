## DEPLOY A CONSUL CLUSTER IN OVH
## These templates show an example of how to use the consul-cluster
## module to deploy Consul in OVH. ## We deploy two Server
## Groups: one with a small number of Consul nodes and one
## with a larger number of Consul client nodes. Note that these
## templates assume that the Glance Image you provide via the
## image_id input variable is built from the
## examples/consul-glance-image/consul.json Packer template.
terraform {
  required_version = ">= 0.9.3"
}

# AUTOMATICALLY LOOK UP THE LATEST PRE-BUILT GLANCE IMAGE
# !! WARNING !! These exmaple Glance Images are meant only convenience when initially testing this repo. Do NOT use these example images in a production setting because it is important that you consciously think through the configuration you want in your own production image.
#
# NOTE: This Terraform data source must return at least one Image result or the entire template will fail.
data "openstack_images_image_v2" "consul" {
  count       = "${var.image_id == "" ? 1 : 0}"
  name        = "${var.image_name != "" ? var.image_name : lookup(var.image_names, var.region)}"
  most_recent = true
}

data "openstack_networking_subnet_v2" "subnets" {
  count        = "${var.count}"
  subnet_id    = "${length(var.subnet_ids) > 0 ? format("%s", element(var.subnet_ids, count.index)) : ""}"
  cidr         = "${length(var.subnets) > 0 && length(var.subnet_ids) < 1 ? format("%s", element(var.subnets, count.index)): ""}"
  ip_version   = 4
  dhcp_enabled = true
}

data "openstack_networking_network_v2" "ext_net" {
  name      = "Ext-Net"
  tenant_id = ""
}

resource "openstack_networking_secgroup_v2" "servers_sg" {
  name        = "${var.name}_${var.agent_mode}_sg"
  description = "${var.name} security group for consul ${var.agent_mode} hosts"
}

resource "openstack_networking_secgroup_rule_v2" "in_traffic_tcp" {
  count = "${var.count > 0 ? 1  : 0 }"

  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  remote_ip_prefix  = "${var.cidr}"
  security_group_id = "${openstack_networking_secgroup_v2.servers_sg.id}"
}

resource "openstack_networking_secgroup_rule_v2" "in_traffic_udp" {
  count = "${var.count > 0 ? 1  : 0 }"

  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  remote_ip_prefix  = "${var.cidr}"
  security_group_id = "${openstack_networking_secgroup_v2.servers_sg.id}"
}

resource "openstack_networking_secgroup_v2" "public_servers_sg" {
  count       = "${var.associate_public_ipv4 ? 1 : 0}"
  name        = "${var.name}_${var.agent_mode}s_pub_sg"
  description = "${var.name} security group for public ingress traffic on consul ${var.agent_mode} hosts"
}

resource "openstack_networking_port_v2" "public_port_consul" {
  count = "${var.associate_public_ipv4 ? var.count : 0}"
  name  = "${var.name}_consul_public_port_${count.index}"

  # network_id         = "${data.openstack_networking_network_v2.ext_net.network_id}"
  network_id     = "${lookup(var.public_network_ids, var.region)}"
  admin_state_up = "true"

  security_group_ids = [
    "${compact(concat(openstack_networking_secgroup_v2.public_servers_sg.*.id,var.public_security_group_ids))}",
  ]
}

data "template_file" "public_ipv4_addrs" {
  count    = "${var.associate_public_ipv4 ? var.count : 0}"
  template = "${element(compact(split(",", replace(join(",", flatten(openstack_networking_port_v2.public_port_consul.*.all_fixed_ips)), "/[[:alnum:]]+:[^,]+/", ""))), count.index)}"
}

resource "openstack_networking_port_v2" "port_consul" {
  count = "${var.count}"

  name = "${var.name}_consul_port_${count.index}"

  #  network_id         = "${element(data.openstack_networking_subnet_v2.subnets.*.network_id, count.index)}"
  network_id     = "${var.network_id}"
  admin_state_up = "true"

  security_group_ids = [
    "${compact(concat(list(openstack_networking_secgroup_v2.servers_sg.id),var.security_group_ids))}",
  ]

  fixed_ip {
    subnet_id = "${data.openstack_networking_subnet_v2.subnets.*.id[count.index]}"
  }
}

resource "openstack_compute_servergroup_v2" "consul" {
  name     = "${var.name}-consul-${var.agent_mode}s-servergroup"
  policies = ["anti-affinity"]
}

module "userdata" {
  source                  = "./modules/consul-userdata"
  domain                  = "${var.domain}"
  datacenter              = "${var.datacenter}"
  agent_mode              = "${var.agent_mode}"
  agent_tags              = ["${var.agent_tags}"]
  cidr_blocks             = ["${concat(list(var.cidr), data.openstack_networking_subnet_v2.subnets.*.cidr)}"]
  cacert                  = "${var.cacert}"
  bootstrap_expect        = "${var.count}"
  public_facing           = "${var.associate_public_ipv4}"
  ssh_public_keys         = ["${var.ssh_public_keys}"]
  join_ipv4_addr          = ["${coalescelist(var.join_ipv4_addr, flatten(openstack_networking_port_v2.port_consul.*.all_fixed_ips))}"]
  join_ipv4_addr_wan      = ["${var.join_ipv4_addr_wan}"]
  additional_units        = ["${var.additional_units}"]
  additional_unitcontents = ["${var.additional_unitcontents}"]
  additional_filepaths    = ["${var.additional_filepaths}"]
  additional_filecontents = ["${var.additional_filecontents}"]
}

resource "openstack_compute_instance_v2" "public_consul" {
  count    = "${var.associate_public_ipv4 ? var.count : 0}"
  name     = "${var.name}_${count.index}"
  image_id = "${element(coalescelist(data.openstack_images_image_v2.consul.*.id, list(var.image_id)), 0)}"

  flavor_name = "${var.flavor_name != "" ? var.flavor_name : lookup(var.flavor_names, var.region)}"
  user_data   = "${var.ignition_mode ? module.userdata.ignition : module.userdata.cloudinit}"

  network {
    access_network = true
    port           = "${element(openstack_networking_port_v2.port_consul.*.id, count.index)}"
  }

  # Important: orders of network declaration matters because public internet interface must be eth1
  network {
    port = "${element(openstack_networking_port_v2.public_port_consul.*.id, count.index)}"
  }

  scheduler_hints {
    group = "${openstack_compute_servergroup_v2.consul.id}"
  }

  # The Openstack Instances will use these tags to automatically discover each other and form a cluster.
  # Note: As of today, this feature isn't used because it would require to give credentials to every instances with full access to the openstack API.
  # the first version of this module will bootstrap a first node that will be used as a "join ip"
  metadata = "${merge(map(var.cluster_tag_key, var.cluster_tag_value, "consul_mode", var.agent_mode), var.metadata)}"
}

resource "openstack_compute_instance_v2" "consul" {
  count    = "${var.associate_public_ipv4 ? 0 : var.count}"
  name     = "${var.name}_${count.index}"
  image_id = "${element(coalescelist(data.openstack_images_image_v2.consul.*.id, list(var.image_id)), 0)}"

  flavor_name = "${var.flavor_name != "" ? var.flavor_name : lookup(var.flavor_names, var.region)}"
  user_data   = "${var.ignition_mode ? module.userdata.ignition : module.userdata.cloudinit}"

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
  metadata = "${merge(map(var.cluster_tag_key, var.cluster_tag_value, "consul_mode", var.agent_mode), var.metadata)}"
}

module "post_install_consul" {
  source                  = "./modules/install-consul"
  count                   = "${var.post_install_module || var.post_install_modules ? var.count : 0}"
  triggers                = ["${concat(openstack_compute_instance_v2.consul.*.id, openstack_compute_instance_v2.public_consul.*.id)}"]
  ipv4_addrs              = ["${concat(openstack_compute_instance_v2.consul.*.access_ip_v4, openstack_compute_instance_v2.public_consul.*.access_ip_v4)}"]
  ssh_user                = "${var.ssh_user}"
  ssh_private_key         = "${var.ssh_private_key}"
  ssh_bastion_host        = "${var.ssh_bastion_host}"
  ssh_bastion_user        = "${var.ssh_bastion_user}"
  ssh_bastion_private_key = "${var.ssh_bastion_private_key}"
}

module "post_install_dnsmasq" {
  source                  = "./modules/install-dnsmasq"
  count                   = "${var.post_install_module || var.post_install_modules ? var.count : 0}"
  triggers                = ["${concat(openstack_compute_instance_v2.consul.*.id, openstack_compute_instance_v2.public_consul.*.id)}"]
  ipv4_addrs              = ["${concat(openstack_compute_instance_v2.consul.*.access_ip_v4, openstack_compute_instance_v2.public_consul.*.access_ip_v4)}"]
  ssh_user                = "${var.ssh_user}"
  ssh_private_key         = "${var.ssh_private_key}"
  ssh_bastion_host        = "${var.ssh_bastion_host}"
  ssh_bastion_user        = "${var.ssh_bastion_user}"
  ssh_bastion_private_key = "${var.ssh_bastion_private_key}"
}

module "post_install_fabio" {
  source                  = "./modules/install-fabio"
  count                   = "${var.post_install_module || var.post_install_modules ? var.count : 0}"
  triggers                = ["${concat(openstack_compute_instance_v2.consul.*.id, openstack_compute_instance_v2.public_consul.*.id)}"]
  ipv4_addrs              = ["${concat(openstack_compute_instance_v2.consul.*.access_ip_v4, openstack_compute_instance_v2.public_consul.*.access_ip_v4)}"]
  ssh_user                = "${var.ssh_user}"
  ssh_private_key         = "${var.ssh_private_key}"
  ssh_bastion_host        = "${var.ssh_bastion_host}"
  ssh_bastion_user        = "${var.ssh_bastion_user}"
  ssh_bastion_private_key = "${var.ssh_bastion_private_key}"
}

resource "null_resource" "post_provisionning" {
  count = "${length(var.provision_remote_exec) > 0 ? var.count : 0}"

  triggers {
    nodeid             = "${element(coalescelist(openstack_compute_instance_v2.consul.*.id, openstack_compute_instance_v2.public_consul.*.id), count.index)}"
    inline             = "${md5(join("", var.provision_remote_exec))}"
    install_consul_id  = "${var.post_install_module || var.post_install_modules ? element(module.post_install_consul.install_ids, count.index) : ""}"
    install_fabio_id   = "${var.post_install_module || var.post_install_modules ? element(module.post_install_fabio.install_ids, count.index) : ""}"
    install_dnsmasq_id = "${var.post_install_module || var.post_install_modules ? element(module.post_install_dnsmasq.install_ids, count.index) : ""}"
  }

  connection {
    host                = "${element(coalescelist(openstack_compute_instance_v2.consul.*.access_ip_v4, openstack_compute_instance_v2.public_consul.*.access_ip_v4), count.index)}"
    user                = "${var.ssh_user}"
    private_key         = "${var.ssh_private_key}"
    bastion_host        = "${var.ssh_bastion_host}"
    bastion_user        = "${var.ssh_bastion_user}"
    bastion_private_key = "${var.ssh_bastion_private_key}"
  }

  provisioner "remote-exec" {
    inline = ["${var.provision_remote_exec}"]
  }
}

# This is somekind of a hack to ensure that when consul ids is output and made
# available to other resources outside the module, the node has been fully provisionned
data "template_file" "consul_instances_ids" {
  count    = "${var.count}"
  template = "$${consul_id}"

  vars {
    consul_id          = "${element(coalescelist(openstack_compute_instance_v2.consul.*.id, openstack_compute_instance_v2.public_consul.*.id), count.index)}"
    install_consul_id  = "${element(coalescelist(module.post_install_consul.install_ids, list("")), count.index)}"
    install_fabio_id  = "${element(coalescelist(module.post_install_fabio.install_ids, list("")), count.index)}"
    install_dnsmasq_id  = "${element(coalescelist(module.post_install_dnsmasq.install_ids, list("")), count.index)}"
    post_provision_id  = "${element(coalescelist(null_resource.post_provisionning.*.id, list("")), count.index)}"
  }
}

data "template_file" "ipv4_addrs" {
  count    = "${var.count}"
  template = "${element(compact(split(",", replace(join(",", flatten(openstack_networking_port_v2.port_consul.*.all_fixed_ips)), "/[[:alnum:]]+:[^,]+/", ""))), count.index)}"

  vars {
    consul_id = "${element(data.template_file.consul_instances_ids.*.rendered, count.index)}"
  }
}

data "template_file" "public_ipv4_dns" {
  count    = "${var.associate_public_ipv4 ? var.count : 0}"
  template = "ip$${ip4}.ip-$${ip1}-$${ip2}-$${ip3}.$${domain}"

  vars {
    consul_id = "${element(data.template_file.consul_instances_ids.*.rendered, count.index)}"
    ip1       = "${element(split(".", element(data.template_file.public_ipv4_addrs.*.rendered, count.index)), 0)}"
    ip2       = "${element(split(".", element(data.template_file.public_ipv4_addrs.*.rendered, count.index)), 1)}"
    ip3       = "${element(split(".", element(data.template_file.public_ipv4_addrs.*.rendered, count.index)), 2)}"
    ip4       = "${element(split(".", element(data.template_file.public_ipv4_addrs.*.rendered, count.index)), 3)}"
    domain    = "${lookup(var.ip_dns_domains, var.region)}"
  }
}
