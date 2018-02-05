resource "null_resource" "post_install_cfssl" {
  count = "${var.count}"

  triggers {
    trigger = "${element(var.triggers, count.index)}"
  }

  connection {
    host                = "${element(var.ipv4_addrs, count.index)}"
    user                = "${var.ssh_user}"
    private_key         = "${var.ssh_private_key}"
    bastion_host        = "${var.ssh_bastion_host}"
    bastion_user        = "${var.ssh_bastion_user}"
    bastion_private_key = "${var.ssh_bastion_private_key}"
  }

  provisioner "remote-exec" {
    inline = [ "mkdir -p /tmp/install-cfssl" ]
  }

  provisioner "file" {
    source      = "${path.module}/"
    destination = "/tmp/install-cfssl"
  }

  provisioner "remote-exec" {
    inline = [
      "/bin/sh -x /tmp/install-cfssl/install-cfssl --version ${var.cfssl_version} --sha256sum ${var.cfssl_sha256sum}"
    ]
  }
}

output "install_ids" {
  value = ["${null_resource.post_install_cfssl.*.id}"]
}
