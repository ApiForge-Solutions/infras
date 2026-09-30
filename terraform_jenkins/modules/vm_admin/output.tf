output "vm_id" {
  description = "ID de la VM admin créée"
  value       = proxmox_virtual_environment_vm.vm_admin.vm_id
}

output "vm_name" {
  description = "Nom de la VM admin"
  value       = proxmox_virtual_environment_vm.vm_admin.name
}
output "vm_ip" {
  value = try(
    [
      for ip in flatten(proxmox_virtual_environment_vm.vm_admin.ipv4_addresses) :
      ip if ip != "127.0.0.1"
    ][0],
    null
  )
}