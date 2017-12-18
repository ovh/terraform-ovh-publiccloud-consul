# Consul OVH Public Cloud Module

This repo contains a Module for how to deploy a [Consul](https://www.consul.io/) cluster on [OVH Public Cloud](https://ovhcloud.com/) using [Terraform](https://www.terraform.io/). Consul is a distributed, highly-available tool that you can use for service discovery and key/value storage. A Consul cluster typically includes a small number of server nodes, which are responsible for being part of the [consensus quorum](https://www.consul.io/docs/internals/consensus.html), and a larger number of client nodes, which you typically run alongside your apps.

# Usage


```hcl
module "consul_servers" {
  source = "ovh/publiccloud-consul/ovh"

  count             = 3
  name              = "example_consul_cluster"
  cidr              = "10.0.0.0/16"
  region            = "${var.region}"
  datacenter        = "${lower(var.region)}"
  network_id        = "XXX"
  subnet_id         = "YYY"
  ssh_key_pair      = "mykeypair"
  image_id          = "ZZZ"
  cluster_tag_value = "myconsulcluster"

  metadata = {
    Terraform   = "true"
    Environment = "Consul"
  }
}
```

## Examples

This module has the following folder structure:

* [root](.): This folder shows an example of Terraform code which deploys a [Consul](https://www.consul.io/) cluster in [OVH Public Cloud](https://ovhcloud.com/).
* [modules](https://github.com/ovh/terraform-ovh-publiccloud-consul/tree/master/modules): This folder contains the reusable code for this Module, broken down into one or more modules.
* [examples](https://github.com/ovh/terraform-ovh-publiccloud-consul/tree/master/examples): This folder contains examples of how to use the modules.

To deploy Consul servers using this Module:

1. (Optional) Create a Consul Glance Image using a Packer template that references the [install-consul module](https://github.com/ovh/terraform-ovh-publiccloud-consul/tree/master/modules/install-consul).
   Here is an [example Packer template](https://github.com/ovh/terraform-ovh-publiccloud-consul/tree/master/examples/consul-glance-image#quick-start). 
      
1. Deploy that Image using the Terraform [consul-cluster example](https://github.com/ovh/terraform-ovh-publiccloud-consul/tree/master/examples/consul-cluster). If you prebuilt a consul glance image with packer, you can comment the post provisionning modules arguments.

## How do I contribute to this Module?

Contributions are very welcome! Check out the [Contribution Guidelines](https://github.com/ovh/terraform-ovh-publiccloud-consul/tree/master/CONTRIBUTING.md) for instructions.

## Authors

Module managed by [Yann Degat](https://github.com/yanndegat).

This module was originally based on the [terraform-aws-consul module](https://github.com/hashicorp/terraform-aws-consul/) by [Gruntwork](https://gruntowrk.io)

## License

The 3-Clause BSD License. See [LICENSE](https://github.com/ovh/terraform-ovh-publiccloud-consul/tree/master/LICENSE) for full details.
