output "security_group_id" {
  value = "${openstack_networking_secgroup_v2.servers_sg.id}"
}

output "public_security_group_id" {
  value = "${openstack_networking_secgroup_v2.public_servers_sg.id}"
}

output "instance_ids" {
  value = ["${concat(openstack_compute_instance_v2.consul.*.id, openstack_compute_instance_v2.public_consul.*.id)}"]
}

output "ipv4_addrs" {
  value = ["${flatten(openstack_networking_port_v2.port_consul.*.all_fixed_ips)}"]
}

output "public_ipv4_addrs" {
  value = ["${flatten(openstack_networking_port_v2.public_port_consul.*.all_fixed_ips)}"]
}
