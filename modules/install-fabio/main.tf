resource "null_resource" "post_install_module" {
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
    inline = [ "mkdir -p /tmp/install-fabio" ]
  }

  provisioner "file" {
    source      = "${path.module}/"
    destination = "/tmp/install-fabio"
  }

  provisioner "remote-exec" {
    inline = [
      "/bin/sh -x /tmp/install-fabio/install-fabio --version ${var.fabio_version} --sha256sum ${var.fabio_sha256sum}"
    ]
  }

}
