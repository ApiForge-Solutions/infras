output "ansible_inventory" {
  value = {
    masters = {
      for index, vm in module.vm_master :
      "master_0${index + 1}" => vm.vm_ip
    }

    workers = {
      for index, vm in module.vm_worker :
      "worker_0${index + 1}" => vm.vm_ip
    }

    minio = {
      minio_server = module.vm_Minio.vm_ip
    }

    monitoring = {
      monitoring_server = module.vm_Prometheus.vm_ip
    }
  }
}

#output "vm_id" {
#  description = "ID de la VM admin créée"
#  value       = proxmox_virtual_environment_vm.vm_admin.vm_id
#}
#
#output "vm_name" {
#  description = "Nom de la VM admin"
#  value       = proxmox_virtual_environment_vm.vm_admin.name
#}
#output "vm_ip" {
#  value = try(
#    [
#      for ip in flatten(proxmox_virtual_environment_vm.vm_admin.ipv4_addresses) :
#      ip if ip != "127.0.0.1"
#    ][0],
#    null
#  )
#}