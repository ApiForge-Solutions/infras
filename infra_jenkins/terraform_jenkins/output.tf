output "ansible_inventory" {
  value = {
    jenkins = module.vm_Jenkins.vm_ip

  }
}