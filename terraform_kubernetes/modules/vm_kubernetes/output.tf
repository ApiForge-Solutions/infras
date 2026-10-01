output "vm_id" {
  value = proxmox_virtual_environment_vm.vm_api.vm_id
}

output "vm_name" {
  value = proxmox_virtual_environment_vm.vm_api.name
}

output "vm_ip" {
  value = try(
    [
      for ip in flatten(proxmox_virtual_environment_vm.vm_api.ipv4_addresses) :
      ip if ip != "127.0.0.1"
    ][0],
    null
  )
}
  