output "vnet_name" {
  value = data.proxmox_sdn_vnet.network.id
}

output "gateway" {
  value = data.proxmox_sdn_subnet.network.gateway
}

output "cidr" {
  value = data.proxmox_sdn_subnet.network.cidr
}