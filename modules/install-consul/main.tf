resource "null_resource" "post_install_consul" {
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
    inline = ["mkdir -p /tmp/install-consul"]
  }

  provisioner "file" {
    source      = "${path.module}/"
    destination = "/tmp/install-consul"
  }

  provisioner "remote-exec" {
    inline = [
      "/bin/sh -x /tmp/install-consul/install-consul --path ${var.install_dir} --version ${var.consul_version} --sha256sum ${var.consul_sha256sum}",
      "sudo systemctl restart consul.path",
    ]
  }
}

output "install_ids" {
  value = ["${null_resource.post_install_consul.*.id}"]
}
