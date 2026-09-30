output "vnet_name" {
  value = proxmox_sdn_vnet.network.id
}

output "gateway" {
  value = proxmox_sdn_subnet.network.gateway
}

output "cidr" {
  value = proxmox_sdn_subnet.network.cidr
}