# Cfssl Install Script

This folder contains a script for installing [Cfssl](https://github.com/cfssl/cfssl) and its dependencies.

This script has been tested on the Container Linux & CentOS 7 operating systems.

There is a good chance it will work on other flavors of CentOS and RHEL as well.

## Quick start

<!-- TODO: update the clone URL to the final URL when this Module is released -->

To install cfssl, use `git` to clone this repository at a specific tag (see the [releases page](../../../../releases) 
for all available tags) and run the `install-cfssl` script:

```
git clone --branch <VERSION> https://github.com/ovh/terraform-ovh-publiccloud-consul.git
terraform-ovh-publiccloud-consul/modules/install-cfssl/install-cfssl --version ... --sha256sum ...
```

The `install-cfssl` script will install cfssl.
It contains a binary and an associated systemd service definition which can be used to start cfssl and configure it automatically.

We recommend running the `install-cfssl` script as part of a [Packer](https://www.packer.io/) template to create a cfssl [Glance Image](https://docs.openstack.org/glance/latest/) (see the [consul-glance-image example](../../examples/consul-glance-image) for a fully-working sample code). 

## Command line Arguments

The `install-cfssl` script takes the following arguments:

* `version VERSION`: Install cfssl version VERSION. Required. 
* `path DIR`: Install cfssl into folder DIR. Optional.
* `user USER`: The install dirs will be owned by user USER. Optional.

Example:

```
install-cfssl --version R1.2 --sha256sum eb34ab2179e0b67c29fd55f52422a94fe751527b06a403a79325fed7cf0145bd
```

## How it works

The `install-cfssl` script does the following:

1. [Download the cfssl binary](#download-cfssl-binary)
1. [Install Cfssl Systemd template unit](#install-cfssl-systemd-template-unit)


### Download Cfssl binary

Downloads the Cfssl binary from the [github repo](https://github.com/cfssl/cfssl) 
and verifies it according to the checksum given in argument before putting it 
in the `/opt/cfssl/bin` directory.

### Install Cfssl Systemd template unit

Installs the following:

* `cfssl.service`: Install systemd template service into `/etc/systemd/system/`. 
  cfssl genererates its own cacert is none is present in `/opt/cfssl/cacert/`,
  then generates its own tls sslserver keypair and starts serving on `https://0.0.0.0:8888` 
  by default.
* `cfssl.path`: Install systemd template service into `/etc/systemd/system/`. 
  This unit will start cfssl if a `cfssl.conf` file is present in the `/etc/sysconfig/` 
  directory.
* `cfssl-register.service`: Install systemd template service into `/etc/systemd/system/`. 
  this services starts if a `consul` agent is running and registers the cacert in 
  the consul kv store under the `cacerts/` prefix, along with the cfssl service in the consul
  catalog.


### Using this script as a terraform module

The install script can also be post provisionned using this folder as a terraform module.

Here's a usage example:


```hcl

module "provision_cfssl" {
  source                  = "github.com/ovh/terraform-ovh-publiccloud-consul//modules/install-cfssl"
  count                   = N
  fabio_version           = "R1.2"
  fabio_sha256sum         = "...."
  triggers                = ["A list of trigger values"]
  ipv4_addrs              = ["192.168.1.200"]
  ssh_user                = "centos"
  ssh_private_key         = "${file("~/.ssh/id_rsa")}"
  ssh_bastion_host        = "34.234.13.XX"
  ssh_bastion_user        = "core"
  ssh_bastion_private_key = "${file("~/.ssh/id_rsa")}"
}
```
