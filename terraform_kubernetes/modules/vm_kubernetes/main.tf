terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.112.0"
    }
  }
}





resource "proxmox_virtual_environment_vm" "vm_api" {
  name      = var.name
  vm_id     = var.vm_id
  node_name = var.virtual_environment_node_name

  started        = true
  stop_on_destroy = true

  machine     = "q35"
  bios        = "ovmf"
  description = "Managed by Terraform"
agent {
  enabled = true
}
  cpu {
    cores = var.cpu_cores
  }

  memory {
    dedicated = var.memory
  }
   
scsi_hardware = "virtio-scsi-single"
  efi_disk {
    datastore_id = var.disk_datastore_id
    type         = "4m"
  }

  disk {
    datastore_id = var.disk_datastore_id
    import_from  = var.ubuntu_image_id

    interface = "scsi0"
    iothread  = true
    size      = 10
    discard   = "on"
  }

  initialization {
    datastore_id = var.disk_datastore_id

    ip_config {
  ipv4 {
     address = "dhcp"
  }

}
   

    user_account {
      username = var.username
      password = var.password
      keys     = [var.ssh_public_key]
    }
      vendor_data_file_id = "local:snippets/cloud-init.yaml"
  }

  network_device {
    bridge = var.network_bridge
  }

}
