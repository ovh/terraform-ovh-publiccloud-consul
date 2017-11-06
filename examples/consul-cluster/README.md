Consul Cluster example
==========

Configuration in this directory creates set of openstack resources which will spawn all the OVH Public Cloud infrastructure required to spawn an unsecure cluster consul and a client node.

It will: 

* Create an openstack keypair to be deployed on the cluster nodes for further administration.
* Create the privates networks in which the consul cluster and consul client node will be spawned.
* Spawn a consul cluster with 3 server nodes.
* Spawn a private instance with a consul agent node in client mode that will automatically join the consul cluster.

NOTES:

* In a real scenario, you probably to setup TLS encryption and a consul encrypt key for RPC communication.
* You may want to refer to the [network module](https://github.com/ovh/terraform-ovh-publiccloud-spark) to see how to associate a VRack to your project, use a preexisting network, spawn the cluster in a specific VLAN ID, ...

Usage
=====

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan -var project_id=...
$ terraform apply -var project_id=...
...
$ terraform destroy -var project_id=...
```

Note that this example may create resources which can cost money (Openstack Instance, for example). Run `terraform destroy` when you don't need these resources.
