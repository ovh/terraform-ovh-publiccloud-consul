provider "ovh" {
  endpoint = "ovh-eu"
}

provider "openstack" {
  region = "${var.region}"
  alias  = "${var.region}"
}

# Import Keypair
resource "openstack_compute_keypair_v2" "keypair" {
  name       = "my-consul-keypair"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

module "network" {
  source  = "ovh/publiccloud-network/ovh"
  version = ">= 0.0.7"

  attach_vrack    = false
  project_id      = "${var.project_id}"
  name            = "example_consul_cluster"
  cidr            = "10.0.0.0/16"
  region          = "${var.region}"
  public_subnets  = ["10.0.0.0/24"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  nat_as_bastion     = true

  ssh_public_keys = ["${openstack_compute_keypair_v2.keypair.public_key}"]

  metadata = {
    Terraform   = "true"
    Environment = "Consul"
  }

  providers = {
    "openstack" = "openstack.${var.region}"
  }
}

module "consul_servers" {
  #  source          = "ovh/publiccloud-consul/ovh"
  #  version         = ">= 0.0.6"
  source = "../.."

  count           = 3
  name            = "example_consul_cluster"
  cidr            = "10.0.0.0/16"
  region          = "${var.region}"
  datacenter      = "${lower(var.region)}"
  subnet_ids      = ["${module.network.private_subnets[0]}"]
  ssh_public_keys = ["${openstack_compute_keypair_v2.keypair.public_key}"]

  image_name              = "Centos 7"
  post_install_module     = true
  ssh_user                = "centos"
  ssh_private_key         = "${file("~/.ssh/id_rsa")}"
  ssh_bastion_host        = "${module.network.nat_public_ips[0]}"
  ssh_bastion_user        = "core"
  ssh_bastion_private_key = "${file("~/.ssh/id_rsa")}"

  # as of today, this is not used but soon will be, so variable is made mandatory to
  # avoid future breaking change.
  cluster_tag_value = "test"

  metadata = {
    Terraform   = "true"
    Environment = "Consul"
  }

  providers = {
    "openstack" = "openstack.${var.region}"
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
  cidr_blocks     = ["10.0.0.0/16"]
  ssh_public_keys = ["${openstack_compute_keypair_v2.keypair.public_key}"]
  join_ipv4_addr  = ["${module.consul_servers.ipv4_addrs}"]
}

resource "openstack_compute_instance_v2" "my_private_instance" {
  name        = "example_consul_client"
  image_name  = "Centos 7"
  flavor_name = "s1-8"
  user_data   = "${module.userdata.cloudinit}"

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
  ssh_bastion_host        = "${module.network.nat_public_ips[0]}"
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
  ssh_bastion_host        = "${module.network.nat_public_ips[0]}"
  ssh_bastion_user        = "core"
  ssh_bastion_private_key = "${file("~/.ssh/id_rsa")}"
}
