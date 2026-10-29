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
  }
}