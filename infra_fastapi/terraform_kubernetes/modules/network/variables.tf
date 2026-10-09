
variable "node_name" {
  type = string
}

variable "zone_name" {
  type    = string
}

variable "vnet_name" {
  type    = string
}

variable "cidr" {
  type    = string
  default = "10.10.10.0/24"
}

variable "gateway" {
  type    = string
  default = "10.10.10.1"
}

variable "dhcp_start" {
  type    = string
  default = "10.10.10.100"
}

variable "dhcp_end" {
  type    = string
  default = "10.10.10.200"
}

