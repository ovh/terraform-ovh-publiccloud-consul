# Consul Run Script

This folder contains a script for configuring and running Consul on an [OVH Public Cloud](https://www.ovh.com/fr/public-cloud/instances/) server. This script has been tested on the CentOS 7 operating system.

There is a good chance it will work on other flavors of CentOS, and RHEL as well.

## Quick start

This script assumes you installed it, plus all of its dependencies (including Consul itself), using the [install-consul module](../../modules/install-consul). The default install path is `/opt/consul/bin`, so to start Consul in server mode, 
you run:

```
/opt/consul/bin/consul-manage start
```

This will:

1. Generate a Consul configuration file called `00-default.json` in the Consul config dir (default: `/opt/consul/config`).
   See [Consul configuration](#consul-configuration) for details on what this configuration file will contain and how to override it with your own configuration.
   
We recommend using the `consul.service` systemd service to start the consul agent.
We also recommand to set `/etc/sysconfig/consul.conf` the as part of [User 
Data](https://docs.openstack.org/heat/latest/template_guide/software_deployment.html).

See the [consul-cluster example](../../MAIN.md) for fully-working sample code.


## Consul configuration

`consul-manage` generates a configuration file for Consul called `00-default.json` that tries to figure out reasonable defaults for a Consul cluster in OVH. Check out the [Consul Configuration Files 
documentation](https://www.consul.io/docs/agent/options.html#configuration-files) for what configuration settings are available.
  
  
### Default configuration

`consul-manage` sets the following configuration values by default:
  
* [advertise_addr](https://www.consul.io/docs/agent/options.html#advertise_addr): Set to the Instance's private IP address, as fetched from [Metadata](https://docs.openstack.org/dragonflow/latest/specs/metadata_service.html), fallback to the IPv4 used to route the `$PRIVATE_NETWORK` cidr block (set as an environment variable), then to the publiv IPv4.

* [bind_addr](https://www.consul.io/docs/agent/options.html#bind_addr):  Set to the Instance's private IP address, as fetched from [Metadata](https://docs.openstack.org/dragonflow/latest/specs/metadata_service.html), fallback to the IPv4 used to route the `$PRIVATE_NETWORK` cidr block (set as an environment variable), then to the publiv IPv4.

* [bootstrap_expect](https://www.consul.io/docs/agent/options.html#bootstrap_expect): If `--server` is set, set this config based on the `$CONSUL_BOOTSTRAP_EXPECT` environment variable, defaults to "3".

* [client_addr](https://www.consul.io/docs/agent/options.html#client_addr): Set to 127.0.0.1 so you can access the client only from the instance. If you want to access the consul cluster from outside, you'll then have to bootstrap an "edge node".

* [datacenter](https://www.consul.io/docs/agent/options.html#datacenter): Set to the `$CONSUL_DATACENTER` environment variable, defaults to "dc1".

* [node_name](https://www.consul.io/docs/agent/options.html#node_name): Set to the instance id, as fetched from [Metadata](https://docs.openstack.org/dragonflow/latest/specs/metadata_service.html), fallback to the private ipv4.

* [retry_join](https://www.consul.io/docs/agent/options.html#retry_join): Set to the value of the `$JOIN_IPV4_ADDR` environment variable. It can be set to a list of IPv4 separated by commas

* [retry_join_wan](https://www.consul.io/docs/agent/options.html#retry_join_wan): Set to the value of the `$JOIN_IPV4_ADDR_WAN` environment variable. It can be set to a list of IPv4 separated by commas

* [retry_join autojoin](https://www.consul.io/docs/agent/options.html#retry_join): If the `$CONSUL_AUTOJOIN` environment variable is set to "os" , look up the OS Instances tags following keys for this setting, [see Go Discover](https://github.com/hashicorp/go-discover) for more info.
    * [tag_key](https://www.consul.io/docs/agent/options.html#tag_key): Set to the value of the `$CONSUL_AUTOJOIN_OS_TAG_KEY` environment variable.
      argument.
    * [tag_value](https://www.consul.io/docs/agent/options.html#tag_value): Set to the value of the  `$CONSUL_AUTOJOIN_OS_TAG_VALUE` environement variable.
    * other options shall be set through environment variables according to the [OS config options](https://github.com/hashicorp/go-discover/blob/master/provider/os/os_discover.go#L23-L38).
      
* [server](https://www.consul.io/docs/agent/options.html#server): Set to true if `$CONSUL_MODE` is set to "server", defaults to "client".

### Overriding the configuration

To override the default configuration, simply put your own configuration file in the Consul config folder (default: 
`/opt/consul/config`), but with a name that comes later in the alphabet than `00-default.json` (e.g. 
`01-my-custom-config.json`). Consul will load all the `.json` configuration files in the config dir and 
[merge them together in alphabetical order](https://www.consul.io/docs/agent/options.html#_config_dir), so that settings in files that come later in the alphabet will override the earlier ones. 

For example, to override the default `retry_join` settings, you could create a file called `tags.json` with the
contents:

```json
{
  "retry_join": {
    "provider": "os",
    "tag_key": "custom-key",
    "tag_value": "custom-value",
    "os_region": "GRA3"
  }
}
```

### Required permissions

The `autojoin` mode assumes Openstack RC environment variables are properly set.

## How do you handle encryption?

Consul can encrypt all of its network traffic (see the [encryption docs for 
details](https://www.consul.io/docs/agent/encryption.html)), but by default, encryption is not enabled in this 
Module. To enable encryption, you need to do the following:

1. [Gossip encryption: provide an encryption key](#gossip-encryption-provide-an-encryption-key)
1. [RPC encryption: provide TLS certificates](#rpc-encryption-provide-tls-certificates)


### Gossip encryption: provide an encryption key

To enable Gossip encryption, you need to provide a 16-byte, Base64-encoded encryption key, which you can generate using
the [consul keygen command](https://www.consul.io/docs/commands/keygen.html). You can put the key in a Consul 
configuration file (e.g. `encryption.json`) in the Consul config dir (default location: `/opt/consul/config`):

```json
{
  "encrypt": "cg8StVXbQJ0gPvMd9o7yrg=="
}
```


### RPC encryption: provide TLS certificates

To enable RPC encryption, you need to provide the paths to the CA and signing keys ([here is a tutorial on generating 
these keys](http://russellsimpkins.blogspot.com/2015/10/consul-adding-tls-using-self-signed.html)). You can specify 
these paths in a Consul configuration file (e.g. `encryption.json`) in the Consul config dir (default location: 
`/opt/consul/config`):

```json
{
  "ca_file": "/opt/consul/tls/certs/ca-bundle.crt",
  "cert_file": "/opt/consul/tls/certs/my.crt",
  "key_file": "/opt/consul/tls/private/my.key"
}
```

You will also want to set the [verify_incoming](https://www.consul.io/docs/agent/options.html#verify_incoming) and
[verify_outgoing](https://www.consul.io/docs/agent/options.html#verify_outgoing) settings to verify TLS certs on 
incoming and outgoing connections, respectively:

```json
{
  "ca_file": "/opt/consul/tls/certs/ca-bundle.crt",
  "cert_file": "/opt/consul/tls/certs/my.crt",
  "key_file": "/opt/consul/tls/private/my.key",
  "verify_incoming": true,
  "verify_outgoing": true
}
```
