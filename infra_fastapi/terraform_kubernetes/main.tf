terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.112.0"
    }
  }
}

provider "proxmox" {
  endpoint  = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  api_token = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  insecure  = true

  #  backend "http" {}

}
data "proxmox_file" "ubuntu_cloud_image" {
  node_name    = var.virtual_environment_node_name
  datastore_id = "local"
  content_type = "import"
  file_name    = "ubuntu-24.04-server-cloudimg-amd64.qcow2"
}

module "network" {
  source = "./modules/network"

  zone_name = var.zone_name
  vnet_name = var.vnet_name
  node_name = var.virtual_environment_node_name

}

module "vm_master" {
  count  = var.master_count
  source = "./modules/vm_kubernetes"

  name                          = "master-${count.index + 1}"
  vm_id                         = 101 + count.index
  virtual_environment_node_name = var.virtual_environment_node_name
  ssh_public_key                = var.ssh_public_key
  network_bridge                = module.network.vnet_name
  disk_datastore_id             = var.disk_datastore_id
  ubuntu_image_id               = data.proxmox_file.ubuntu_cloud_image.id
  password                      = var.password
  
}

module "vm_worker" {
  count  = var.worker_count
  source = "./modules/vm_kubernetes"

  name                          = "worker-${count.index + 1}"
  vm_id                         = 201 + count.index
  virtual_environment_node_name = var.virtual_environment_node_name
  ssh_public_key                = var.ssh_public_key
  network_bridge                = module.network.vnet_name
  disk_datastore_id             = var.disk_datastore_id
  ubuntu_image_id               = data.proxmox_file.ubuntu_cloud_image.id
  password                      = var.password
}


module "vm_Minio" {
  source = "./modules/vm_admin"

  name                          = "Minio"
  vm_id                         = 302
  virtual_environment_node_name = var.virtual_environment_node_name
  ssh_public_key                = var.ssh_public_key
  password                      = var.password 
  network_bridge                = module.network.vnet_name
  disk_datastore_id             = var.disk_datastore_id
  ubuntu_image_id               = data.proxmox_file.ubuntu_cloud_image.id

}


