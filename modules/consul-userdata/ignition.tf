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

data "ignition_systemd_unit" "additional-units" {
  count   = "${length(var.additional_units)}"
  enabled = true
  name    = "${var.additional_units[count.index]}"
  content = "${var.additional_unitcontents[count.index]}"
}

data "ignition_systemd_unit" "update-ca-cert" {
  name    = "update-ca-cert.service"
  enabled = true

  content = <<CONTENT
[Unit]
Description=Update cacert
[Service]
Type=oneshot
RemainAfterExit=true
ExecStart=/usr/sbin/update-ca-certificates
[Install]
WantedBy=network.target
CONTENT
}

data "ignition_user" "core" {
  name                = "core"
  ssh_authorized_keys = ["${var.ssh_public_keys}"]
}

data "ignition_config" "coreos" {
  users = ["${data.ignition_user.core.id}"]

  systemd = [
    "${data.ignition_systemd_unit.update-ca-cert.id}",
    "${data.ignition_systemd_unit.additional-units.*.id}",
  ]

  networkd = [
    "${data.ignition_networkd_unit.eth0.id}",
  ]

  files = [
    "${data.ignition_file.additional-files.*.id}",
    "${data.ignition_file.cacert.*.id}",
    "${data.ignition_file.consul-conf.id}",
  ]
}
