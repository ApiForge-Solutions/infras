# ============================================================
# VMs Kubernetes
# ============================================================

virtual_environment_node_name = "jul26-bootcamp-devops-fastapi"
zone_name                     = "apizone"
vnet_name                     = "apivnet"
disk_datastore_id             = "vmdata"
worker_count                  = "2"
master_count                  = "3"
cpu_cores                     = "2"
memory                        = "2048"
network_bridge                = "vmbr0"
username                      = "ubuntu"

# -----------------------------
# Réseau
# -----------------------------

cidr       = "10.10.10.0/24"
gateway    = "10.10.10.1"
dhcp_start = "10.10.10.2"
dhcp_end   = "10.10.10.100"
dns        = "1.1.1.1"