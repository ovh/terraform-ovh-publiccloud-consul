variable "region" {
  description = "The id of the openstack region"
}

variable "project_id" {
  description = "The id of the openstack project"
}

variable "cidr" {
  description = "The cidr of the network"
  default     = "10.133.0.0/16"
}
