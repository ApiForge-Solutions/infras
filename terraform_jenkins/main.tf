terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.112.0"
    }
  }
}

provider "proxmox" {
  endpoint  = "https://0.0.0.0.0:8006/"
  api_token = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  insecure  = true

  #  backend "http" {}

}
resource "proxmox_download_file" "ubuntu_cloud_image" {
  content_type = "import"
  datastore_id = "local"
  node_name    = var.virtual_environment_node_name

  url = "https://cloud-images.ubuntu.com/releases/server/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img"

  file_name = "ubuntu-24.04-server-cloudimg-amd64.qcow2"
}

module "network" {
  source = "./modules/network"

  zone_name = var.zone_name
  vnet_name = var.vnet_name
  node_name = var.virtual_environment_node_name

}
module "vm_Jenkins" {
  source = "./modules/vm_admin"

  name                          = "Jenkins"
  vm_id                         = 301
  virtual_environment_node_name = var.virtual_environment_node_name
  ssh_public_key                = var.ssh_public_key
  password                      = var.password
  network_bridge                = module.network.vnet_name
  disk_datastore_id             = var.disk_datastore_id
  ubuntu_image_id               = proxmox_download_file.ubuntu_cloud_image.id

}