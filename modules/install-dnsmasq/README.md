# Dnsmasq Install Script

This folder contains a script for installing [Dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html) and configuring it to forward requests for a specific domain to Consul. This way, you can easily use Consul as your DNS server for domain names such as `foo.service.consul`, where `foo` is a service registered with Consul (see the [Registering Services docs](https://www.consul.io/intro/getting-started/services.html) for instructions on registering your services with Consul). All other domain names will continue to be resolved via the default resolver on your OS. See the [Consul DNS Forwarding Guide](https://www.consul.io/docs/guides/forwarding.html) for more info. 

This script has been tested on CoreOS & CentOS 7 operating systems.

There is a good chance it will work on other flavors of CentOS, and RHEL as well.

## Quick start

To install Dnsmasq, use `git` to clone this repository at a specific tag (see the [releases page](../../../../releases) for all available tags) and run the `install-dnsmasq` script:

```
git clone --branch <VERSION> https://github.com/hashicorp/terraform-aws-consul.git
terraform-aws-consul/modules/install-dnsmasq/install-dnsmasq
```

Note: by default, the `install-dnsmasq` script assumes that a Consul agent is already running locally and connected to a Consul cluster. After the install completes, restart `dnsmasq` (e.g. `sudo systemctl restart dnsmasq`) and queries to the `.consul` domain will be resolved via Consul:

```
dig +short consul.service.consul
```
We recommend running the `install-dnsmasq` script as part of a [Packer](https://www.packer.io/) template to create a Consul [Glance Image](https://docs.openstack.org/glance/latest/) (see the 
[consul-glance-image example](../../examples/consul-glance-image) for a fully-working sample code).

## Command line Arguments

The `install-dnsmasq` script takes no argument.

Example:

```
install-dnsmasq
```

## Dnsmasq setup

The dnsmasq setup will

1. prepend the dnsmasq server for the networking dns resolver
2. forward the dns request on the consul domain to 127.0.0.1 8600 which should be resolved by consul.

## Troubleshooting

Add the `+trace` argument to `dig` commands to more clearly see what's going on:

```
dig vault.service.consul +trace
```
