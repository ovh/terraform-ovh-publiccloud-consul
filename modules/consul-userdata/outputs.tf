output "ignition" {
  description = "The ignition representation of the userdata"
  value       = "${data.ignition_config.coreos.rendered}"
}

output "cloudinit" {
  description = "The cloudinit representation of the userdata"
  value       = "${data.template_cloudinit_config.config.rendered}"
}
