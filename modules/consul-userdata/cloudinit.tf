locals {
  ip_route_add_tpl        = "- ip route add %s dev %s scope link metric 0"
  eth_route_tpl           = "%s dev %s scope link metric 0"
}

data "template_file" "additional_files" {
  count = "${length(var.additional_filepaths)}"

  template = <<TPL
- path: $${path}
  content: |
     $${content}
TPL

  vars {
    path    = "${var.additional_filepaths[count.index]}"
    content = "${indent(5, var.additional_filecontents[count.index])}"
  }
}

# Render a multi-part cloudinit config making use of the part
# above, and other source files
data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"

    content = <<CLOUDCONFIG
#cloud-config
## This route has to be added in order to reach other subnets of the network
ssh_authorized_keys:
  ${length(var.ssh_public_keys) > 0 ? indent(2, join("\n", formatlist("- %s", var.ssh_public_keys))) : ""}
bootcmd:
  ${indent(2, join("\n", formatlist(local.ip_route_add_tpl, var.cidr_blocks, "eth0")))}
  ${var.public_facing? format(local.ip_route_add_tpl, "0.0.0.0/0", "eth1") : ""}
runcmd:
  ${length(var.additional_units) > 0 ? indent(2, join("\n", concat(formatlist("- systemctl enable %s", var.additional_units), formatlist("- systemctl start %s", var.additional_units)))) : ""}
ca-certs:
  trusted:
    - ${var.cacert}
write_files:
  ${indent(2, join("\n", data.template_file.additional_files.*.rendered))}
  - path: /etc/sysconfig/consul.conf
    content: |
      DOMAIN=${var.domain}
      DATACENTER=${var.datacenter}
      CONSUL_MODE=${var.agent_mode}
      CONSUL_BOOTSTRAP_EXPECT=${var.bootstrap_expect}
      PRIVATE_NETWORK=${var.cidr_blocks[0]}
      JOIN_IPV4_ADDR=${join(",", var.join_ipv4_addr)}
      JOIN_IPV4_ADDR_WAN=${join(",", var.join_ipv4_addr_wan)}
      CONSUL_AGENT_TAGS=${join(",", var.agent_tags)}
  - path: /etc/sysconfig/network-scripts/route-eth0
    content: |
      ${indent(6, join("\n", formatlist(local.eth_route_tpl, var.cidr_blocks, "eth0")))}
  - path: /etc/sysconfig/network-scripts/route-eth1
    content: |
      ${format(local.eth_route_tpl, "0.0.0.0/0", "eth1")}
CLOUDCONFIG
  }
}
