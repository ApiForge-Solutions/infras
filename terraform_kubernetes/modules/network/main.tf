terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.112.0"
    }
  }
}

data "proxmox_sdn_zone_simple" "network" {
  id = var.zone_name
}

data "proxmox_sdn_vnet" "network" {
  id = var.vnet_name
}

data "proxmox_sdn_subnet" "network" {
  vnet = data.proxmox_sdn_vnet.network.id
  cidr = var.cidr
}

resource "proxmox_sdn_applier" "network" {
  depends_on = [
    data.proxmox_sdn_zone_simple.network,
    data.proxmox_sdn_vnet.network,
    data.proxmox_sdn_subnet.network
  ]
}