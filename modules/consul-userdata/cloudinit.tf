locals {
  ip_route_add_tpl = "- ip route add %s dev %s scope link metric 0"
  eth_route_tpl    = "%s dev %s scope link metric 0"
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

data "template_file" "cfssl_ca_files" {
  template = <<TPL
- path: /opt/cfssl/cacert/ca.pem
  permissions: '0644'
  owner: cfssl:cfssl
  content: |
     ${indent(5, var.cacert)}
- path: /opt/cfssl/cacert/ca-key.pem
  permissions: '0600'
  owner: cfssl:cfssl
  content: |
     ${indent(5, var.cacert_key)}
TPL
}


data "template_file" "cfssl_files" {
  count = "${var.count}"

  template = <<TPL
${var.count == 0 && var.cacert != "" && var.cacert_key != "" ? data.template_file.cfssl_ca_files.rendered : ""}
- path: /etc/sysconfig/cfssl.conf
  mode: 0644
  content: |
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
     CACERTS_INSTALL_DIR=/etc/pki/ca-trust/source/anchors
TPL
}

# Render a multi-part cloudinit config making use of the part
# above, and other source files
data "template_cloudinit_config" "config" {
  count         = "${var.ignition_mode ? 0 : var.count}"
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
runcmd:
  ${length(var.additional_units) > 0 ? indent(2, join("\n", concat(formatlist("- systemctl enable %s", var.additional_units), formatlist("- systemctl start %s", var.additional_units)))) : ""}
ca-certs:
  trusted:
    - ${var.cacert}
write_files:
  ${indent(2, join("\n", data.template_file.additional_files.*.rendered))}
  ${var.cfssl ? indent(2, element(data.template_file.cfssl_files.*.rendered, count.index)) : ""}
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
      CACERTS_INSTALL_DIR=/etc/pki/ca-trust/source/anchors
  - path: /etc/sysconfig/network-scripts/route-eth0
    content: |
      ${indent(6, join("\n", formatlist(local.eth_route_tpl, var.cidr_blocks, "eth0")))}
CLOUDCONFIG
  }
}
