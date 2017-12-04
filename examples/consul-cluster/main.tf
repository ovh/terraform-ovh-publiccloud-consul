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
  source = "ovh/publiccloud-network/ovh"

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
  source = "ovh/publiccloud-consul/ovh"

  count             = 3
  name              = "example_consul_cluster"
  cidr              = "10.0.0.0/16"
  region            = "${var.region}"
  datacenter        = "${lower(var.region)}"
  network_id        = "${module.network.network_id}"
  subnet_id         = "${module.network.private_subnets[0]}"
  ssh_key_pair      = "${openstack_compute_keypair_v2.keypair.name}"

  # TODO: build the consul image with the correct name
  #  image_name  = "Centos 7 Consul"
  image_id    = "478dacd7-8c72-462e-ac45-fc979b5d1238"

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

resource "openstack_compute_instance_v2" "my_private_instance" {
  name        = "example_consul_client"
  # TODO: build the consul image with the correct name
  #  image_name  = "Centos 7 Consul"
  image_id    = "478dacd7-8c72-462e-ac45-fc979b5d1238"
  flavor_name = "s1-8"
  key_pair    = "${openstack_compute_keypair_v2.keypair.name}"

  user_data = <<USERDATA
#cloud-config
## This route has to be added in order to reach other subnets of the network
bootcmd:
  - ip route add 10.0.0.0/16 dev eth0 scope link metric 0
write_files:
  - path: /etc/sysconfig/network-scripts/route-eth0
    content: |
      10.0.0.0/16 dev eth0 scope link metric 0
  - path: /etc/sysconfig/consul.conf
    content: |
      DOMAIN=consul
      DATACENTER=${lower(var.region)}
      CONSUL_MODE=client
      PRIVATE_NETWORK=10.0.0.0/16
      JOIN_IPV4_ADDR=${join(",", module.consul_servers.ipv4_addrs)}
      CONSUL_AGENT_TAGS=myclient
USERDATA

  network {
    port = "${openstack_networking_port_v2.port_private_instance.id}"
  }
}
