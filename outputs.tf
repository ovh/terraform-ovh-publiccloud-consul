output "security_group_id" {
  value = "${openstack_networking_secgroup_v2.servers_sg.id}"
}

output "instance_ids" {
  value = ["${openstack_compute_instance_v2.consul.*.id}"]
}

output "ipv4_addrs" {
  value = ["${flatten(openstack_networking_port_v2.port_consul.*.all_fixed_ips)}"]
}
