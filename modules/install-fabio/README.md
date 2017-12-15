# Fabio Install Script

This folder contains a script for installing [Fabio load balancer](https://github.com/fabiolb/fabio/wiki) and its dependencies.

This script has been tested on the CoreOS & CentOS 7 operating system.

There is a good chance it will work on other flavors of CentOS and RHEL as well.

## Quick start

<!-- TODO: update the clone URL to the final URL when this Module is released -->

To install Fabio, use `git` to clone this repository at a specific tag (see the [releases page](../../../../releases) 
for all available tags) and run the `install-fabio` script:

```
git clone --branch <VERSION> https://github.com/ovh/terraform-ovh-publiccloud-consul.git
terraform-ovh-publiccloud-consul/modules/install-fabio/install-fabio --version ... --sha256sum ...
```

The `install-fabio` script will install Fabio.
It contains a binary and an associated systemd service definition which can be used to start Fabio and configure it to automatically.

We recommend running the `install-fabio` script as part of a [Packer](https://www.packer.io/) template to create a Fabio [Glance Image](https://docs.openstack.org/glance/latest/) (see the [consul-glance-image example](../../examples/consul-glance-image) for a fully-working sample code). You can then deploy the image across a Server Group using the [consul-cluster module](../../modules/consul-cluster) (see the [main ](../../MAIN.md) for fully-working sample code).

## Command line Arguments

The `install-fabio` script takes the following arguments:

* `version VERSION`: Install Consul version VERSION. Required. 
* `path DIR`: Install Consul into folder DIR. Optional.
* `user USER`: The install dirs will be owned by user USER. Optional.

Example:

```
install-fabio --version 1.5.3 --sha256sum ad352a3e770215219c57257c5dcbb14aee83aa50db32ba34431372b570aa58e5
```

## How it works

The `install-fabio` script does the following:

1. [Download the fabio binary](#download-fabio-binary)
1. [Install Fabio Systemd template unit](#install-fabio-systemd-template-unit)


### Download Fabio binary

Downloads the fabio binary from the [github repo](https://github.com/fabiolb/fabio) 
and verifies it according to the checksum given in argument before putting it 
in the `/opt/bin` directory.

### Install Fabio Systemd template unit

Installs the following:

* `fabio@.service`: Install systemd template service into `/etc/systemd/system/`. 

The template will try to load the `/etc/sysconfig/fabio_%i.conf` env file.
