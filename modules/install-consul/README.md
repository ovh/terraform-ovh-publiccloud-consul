# Consul Install Script

This folder contains a script for installing Consul and its dependencies. Use this script to create a Consul [an Openstack Glance Image](https://docs.openstack.org/glance/latest/) that can be deployed in [OVH Public Cloud](https://www.ovh.com/fr/public-cloud/instances/) across a Server Group using the [consul-cluster example](../../examples/consul-cluster).

This script has been tested on CoreOS & CentOS 7 operating system.

There is a good chance it will work on other flavors of CentOS and RHEL as well.

## Quick start

<!-- TODO: update the clone URL to the final URL when this Module is released -->

To install Consul, use `git` to clone this repository at a specific tag (see the [releases page](../../../../releases) 
for all available tags) and run the `install-consul` script:

```
git clone --branch <VERSION> https://github.com/ovh/terraform-ovh-publiccloud-consul.git
terraform-ovh-publiccloud-consul/modules/install-consul/install-consul --version 1.0.0
```

The `install-consul` script will install Consul and its dependencies.
It contains a script and an associated systemd service definition which can be used to start Consul and configure it to automatically join other nodes to form a cluster when the server is booting.

We recommend running the `install-consul` script as part of a [Packer](https://www.packer.io/) template to create a Consul [Glance Image](https://docs.openstack.org/glance/latest/) (see the [consul-glance-image example](../../examples/consul-glance-image) for a fully-working sample code). You can then deploy the image across a Server Group using the [consul-cluster example](../../examples/consul-cluster) (see the [main ](../../MAIN.md) for fully-working sample code).

## Command line Arguments

The `install-consul` script accepts the following arguments:

* `version VERSION`: Install Consul version VERSION. Required. 
* `path DIR`: Install Consul into folder DIR. Optional.
* `user USER`: The install dirs will be owned by user USER. Optional.

Example:

```
install-consul --version 1.0.1 --sha256sum eac5755a1d19e4b93f6ce30caaf7b3bd8add4557b143890b1c07f5614a667a68
```

## How it works

The `install-consul` script does the following:

1. [Create a user and folders for Consul](#create-a-user-and-folders-for-consul)
1. [Install Consul binaries and scripts](#install-consul-binaries-and-scripts)
1. [Disables Firewalld](#disable-firewalld)
1. [Follow-up tasks](#follow-up-tasks)


### Create a user and folders for Consul

Create an OS user named `consul`. Create the following folders, all owned by user `consul`:

* `/opt/consul`: base directory for Consul data (configurable via the `--path` argument).
* `/opt/consul/bin`: directory for Consul binaries.
* `/opt/consul/data`: directory where the Consul agent can store state.
* `/opt/consul/config`: directory where the Consul agent looks up configuration.
* `/opt/consul/log`: directory where Consul will store log output.


### Install Consul binaries and scripts

Install the following:

* `consul`: Download the Consul zip file from the [downloads page](https://www.consul.io/downloads.html) (the version number is configurable via the `--version` argument), and extract the `consul` binary into `/opt/consul/bin`. Add a symlink to the `consul` binary in `/usr/local/bin`.
* `manage scripts`: Copy manage scripts into `/opt/consul/bin`
* `consul.service`: Install associated systemd services into `/etc/systemd/system/`. 

### Disables Firewalld

As of today, firewalld is disabled. The consul setup for firewalld hasn't been implemented. You should be aware of this and have a proper setup of your security group rules.

### Follow-up tasks

After the `install-consul` script finishes running, you may wish to do the following:

1. If you have custom Consul config (`.json`) files, you may want to copy them into the config directory (default: `/opt/consul/config`).
1. If `/usr/local/bin` isn't already part of `PATH`, you should add it so you can run the `consul` command without specifying the full path.
