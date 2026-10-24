terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.112.0"
    }
  }
}

resource "proxmox_sdn_zone_simple" "network" {
  id    = var.zone_name
  nodes = [var.node_name]
  mtu   = 1500

  ipam = "pve"
  dhcp = "dnsmasq"
}

resource "proxmox_sdn_vnet" "network" {
  id   = var.vnet_name
  zone = proxmox_sdn_zone_simple.network.id
}

resource "proxmox_sdn_subnet" "network" {
  vnet    = proxmox_sdn_vnet.network.id
  cidr    = var.cidr
  gateway = var.gateway

  dhcp_range = {
    start_address = var.dhcp_start
    end_address   = var.dhcp_end
  }

  snat = true
}

resource "proxmox_sdn_applier" "network" {
  depends_on = [
    proxmox_sdn_zone_simple.network,
    proxmox_sdn_vnet.network,
    proxmox_sdn_subnet.network
  ]
}