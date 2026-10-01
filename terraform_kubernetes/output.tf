output "ansible_inventory" {
  value = {
   

    masters = [
      for vm in module.vm_master : vm.vm_ip
    ]

    workers = [
      for vm in module.vm_worker : vm.vm_ip
    ]

    minio = module.vm_Minio.vm_ip
  }
}