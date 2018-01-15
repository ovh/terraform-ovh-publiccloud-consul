variable "region" {
  description = "The id of the openstack region"
}

variable "project_id" {
  description = "The id of the openstack project"
}

variable "cidr" {
  description = "The cidr of the network"
  default     = "10.132.0.0/16"
}

variable "public_network_ids" {
  description = "This var is temporary, waiting for next op"
  default = {
    GRA3 = "eecc8610-f977-461c-bad2-917d7be01144"
    DE1  = "ed0ab0c6-93ee-44f8-870b-d103065b1b34"
    BHS3 = "bf8869ea-aaba-4a34-b7e9-9010861ff5f6"
    WAW1 = "6c928965-47ea-463f-acc8-6d4a152e9745"
    UK1  = "6011fbc9-4cbf-46a4-8452-6890a340b60b"
    SBG3 = "ae4fffbd-2cc5-4a34-965b-6b3920276ab3"
  }
}
