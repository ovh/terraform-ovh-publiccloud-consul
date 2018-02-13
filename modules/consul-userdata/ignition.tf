locals {
  network_route_tpl = "[Route]\nDestination=%s\nGatewayOnLink=yes\nRouteMetric=3\nScope=link\nProtocol=kernel"
}

data "ignition_file" "additional-files" {
  count      = "${length(var.additional_filepaths)}"
  filesystem = "root"
  mode       = "0644"
  path       = "${var.additional_filepaths[count.index]}"

  content {
    content = "${var.additional_filecontents[count.index]}"
  }
}

data "ignition_file" "cacert" {
  count      = "${var.cacert != "" ? 1 : 0}"
  filesystem = "root"
  path       = "/etc/ssl/certs/cacert.pem"
  mode       = "0644"

  content {
    content = "${var.cacert}"
  }
}

data "ignition_file" "cfssl-cacert" {
  filesystem = "root"
  path       = "/opt/cfssl/cacert/ca.pem"
  mode       = "0644"

  content {
    content = "${var.cacert}"
  }
}

data "ignition_file" "cfssl-cakey" {
  filesystem = "root"
  path       = "/opt/cfssl/cacert/ca-key.pem"
  mode       = "0600"
  uid        = "1011"

  content {
    content = "${var.cacert_key}"
  }
}

data "ignition_file" "consul-conf" {
  filesystem = "root"
  mode       = "0644"
  path       = "/etc/sysconfig/consul.conf"

  content {
    content = <<CONTENT
DOMAIN=${var.domain}
DATACENTER=${var.datacenter}
CONSUL_MODE=${var.agent_mode}
CONSUL_BOOTSTRAP_EXPECT=${var.bootstrap_expect}
PRIVATE_NETWORK=${var.cidr_blocks[0]}
JOIN_IPV4_ADDR=${join(",", var.join_ipv4_addr)}
JOIN_IPV4_ADDR_WAN=${join(",", var.join_ipv4_addr_wan)}
CONSUL_AGENT_TAGS=${join(",", var.agent_tags)}
CONTENT
  }
}

data "ignition_file" "cfssl-conf" {
  count      = "${var.count}"
  filesystem = "root"
  mode       = "0644"
  path       = "/etc/sysconfig/cfssl.conf"

  content {
    content = <<CONTENT
CFSSL_MODE=${count.index == 0 ? "server" : "off"}
CA_VALIDITY_PERIOD=${var.cfssl_ca_validity_period}
CERT_VALIDITY_PERIOD=${var.cfssl_cert_validity_period}
CN=${var.cfssl_cn == "" ? var.domain : var.cfssl_cn}
C=${var.cfssl_c == "" ? var.datacenter : var.cfssl_c}
L=${var.cfssl_l}
O=${var.cfssl_o}
OU=${var.cfssl_ou}
ST=${var.cfssl_st}
KEY_ALGO=${var.cfssl_key_algo}
KEY_SIZE=${var.cfssl_key_size}
CFSSL_HOSTNAMES=cfssl.service.${var.domain},cfssl.service.${var.datacenter}.${var.domain},127.0.0.1,localhost
CFSSL_BIND=${var.cfssl_bind}
CFSSL_PORT=${var.cfssl_port}
CONTENT
  }
}

data "ignition_networkd_unit" "eth0" {
  name = "10-eth0.network"

  content = <<IGNITION
[Match]
Name=eth0
[Network]
DHCP=ipv4
${join("\n", formatlist(local.network_route_tpl, var.cidr_blocks))}
[DHCP]
RouteMetric=2048
IGNITION
}

data "ignition_networkd_unit" "eth1" {
  name = "10-eth1.network"

  content = <<IGNITION
[Match]
Name=eth1
[Network]
DHCP=ipv4
[DHCP]
RouteMetric=2048
IGNITION
}

data "ignition_systemd_unit" "additional-units" {
  count   = "${length(var.additional_units)}"
  enabled = true
  name    = "${var.additional_units[count.index]}"
  content = "${var.additional_unitcontents[count.index]}"
}


data "ignition_user" "core" {
  name                = "core"
  ssh_authorized_keys = ["${var.ssh_public_keys}"]
}

data "ignition_config" "coreos" {
  count = "${var.ignition_mode ? var.count : 0 }"
  users = ["${data.ignition_user.core.id}"]

  systemd = [
    "${data.ignition_systemd_unit.additional-units.*.id}",
  ]

  networkd = [
    "${data.ignition_networkd_unit.eth0.id}",
    "${data.ignition_networkd_unit.eth1.id}",
  ]

  files = [
    "${data.ignition_file.additional-files.*.id}",
    "${data.ignition_file.cacert.*.id}",
    "${data.ignition_file.consul-conf.id}",
    "${var.cfssl && count.index == 0 ? data.ignition_file.cfssl-cacert.id : ""}",
    "${var.cfssl && count.index == 0 ? data.ignition_file.cfssl-cakey.id : ""}",
    "${var.cfssl ? element(data.ignition_file.cfssl-conf.*.id, count.index) : ""}",
  ]
}
