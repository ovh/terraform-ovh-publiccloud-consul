output "rendered" {
  description = "The representation of the userdata according to `var.ignition_mode`"
  value = ["${coalescelist(data.ignition_config.coreos.*.rendered, data.template_cloudinit_config.config.*.rendered)}"]
}
