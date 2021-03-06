provider "ovh" {
  version  = "~> 0.2"
  endpoint = "ovh-eu"
}

provider "openstack" {
  version = "~> 1.2"
  region  = "${var.region}"
}

module "network" {
  source  = "ovh/publiccloud-network/ovh"
  version = ">= 0.0.20"

  attach_vrack    = false
  project_id      = "${var.project_id}"
  name            = "example_consul_cluster"
  cidr            = "${var.cidr}"
  region          = "${var.region}"
  public_subnets  = ["${cidrsubnet(var.cidr,8,0)}"]
  private_subnets = ["${cidrsubnet(var.cidr,8,1)}", "${cidrsubnet(var.cidr,8,2)}"]

  enable_nat_gateway = true
  single_nat_gateway = true
  nat_as_bastion     = true

  ssh_public_keys = ["${file("~/.ssh/id_rsa.pub")}"]

  metadata = {
    Terraform   = "true"
    Environment = "Consul"
  }
}

module "consul_servers" {
  #  source          = "ovh/publiccloud-consul/ovh"
  #  version         = ">= 0.0.8"
  source = "../.."

  count           = 3
  name            = "example_consul_cluster"
  cidr            = "${var.cidr}"
  region          = "${var.region}"
  datacenter      = "${lower(var.region)}"
  subnet_ids      = ["${module.network.private_subnets[0]}"]
  ssh_public_keys = ["${file("~/.ssh/id_rsa.pub")}"]
  image_name      = "Centos 7"
  cfssl           = true

  ### comment the following block if you're using a glance image with
  ### pre provisionned software.
  ignition_mode = false

  ssh_user                = "centos"
  ssh_private_key         = "${file("~/.ssh/id_rsa")}"
  ssh_bastion_host        = "${module.network.bastion_public_ip}"
  ssh_bastion_user        = "core"
  ssh_bastion_private_key = "${file("~/.ssh/id_rsa")}"

  # as of today, this is not used but soon will be, so variable is made mandatory to
  # avoid future breaking change.
  cluster_tag_value = "test"

  metadata = {
    Terraform   = "true"
    Environment = "Consul"
  }
}

resource "openstack_networking_port_v2" "port_private_instance" {
  name           = "example_consul_client_port"
  network_id     = "${module.network.network_id}"
  admin_state_up = "true"

  fixed_ip {
    subnet_id = "${module.network.private_subnets[1]}"
  }
}

module "userdata" {
  #  source         = "github.com/ovh/terraform-ovh-publiccloud-consul//modules/userdata"
  source          = "../../modules/consul-userdata"
  domain          = "consul"
  datacenter      = "${lower(var.region)}"
  agent_mode      = "client"
  cidr_blocks     = ["${var.cidr}"]
  ssh_public_keys = ["${file("~/.ssh/id_rsa.pub")}"]
  join_ipv4_addr  = ["${module.consul_servers.ipv4_addrs}"]
  ignition_mode   = false
}

resource "openstack_compute_instance_v2" "my_private_instance" {
  name        = "example_consul_client"
  image_name  = "Centos 7"
  flavor_name = "s1-8"
  user_data   = "${module.userdata.rendered[0]}"

  network {
    access_network = true
    port           = "${openstack_networking_port_v2.port_private_instance.id}"
  }
}

module "provision_consul" {
  #  source         = "github.com/ovh/terraform-ovh-publiccloud-consul//modules/install-consul"
  source                  = "../../modules/install-consul"
  triggers                = ["${openstack_compute_instance_v2.my_private_instance.id}"]
  ipv4_addrs              = ["${openstack_compute_instance_v2.my_private_instance.access_ip_v4}"]
  ssh_user                = "centos"
  ssh_private_key         = "${file("~/.ssh/id_rsa")}"
  ssh_bastion_host        = "${module.network.bastion_public_ip}"
  ssh_bastion_user        = "core"
  ssh_bastion_private_key = "${file("~/.ssh/id_rsa")}"
}

module "provision_dnsmasq" {
  #  source         = "github.com/ovh/terraform-ovh-publiccloud-consul//modules/install-dnsmasq"
  source                  = "../../modules/install-dnsmasq"
  triggers                = ["${openstack_compute_instance_v2.my_private_instance.id}"]
  ipv4_addrs              = ["${openstack_compute_instance_v2.my_private_instance.access_ip_v4}"]
  ssh_user                = "centos"
  ssh_private_key         = "${file("~/.ssh/id_rsa")}"
  ssh_bastion_host        = "${module.network.bastion_public_ip}"
  ssh_bastion_user        = "core"
  ssh_bastion_private_key = "${file("~/.ssh/id_rsa")}"
}
