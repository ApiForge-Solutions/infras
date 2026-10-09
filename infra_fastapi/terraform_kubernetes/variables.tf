variable "ssh_public_key" {
  description = "Clé SSH publique utilisée pour les VM"
  type        = string
}
variable "master_count" {
  type    = number
  default = 3
}


variable "worker_count" {
  type    = number
  default = 2
}
variable "virtual_environment_node_name" {
  description = "Nom du node Proxmox"
  type        = string
}
variable "disk_datastore_id" {
  description = "Datastore Proxmox utilisé pour les disques des VM"
  type        = string
}
variable "zone_name" {
  type = string
}

variable "vnet_name" {
  type = string
}
variable "password" {
  description = "Mot de passe de l'utilisateur Ubuntu"
  type        = string
  sensitive   = true
}
variable "cidr" {
  type    = string
  default = "10.10.10.0/24"
}

variable "gateway" {
  type    = string
  default = "10.10.10.1"
}

variable "dhcp_start" {
  type    = string
  default = "10.10.10.100"
}

variable "dhcp_end" {
  type    = string
  default = "10.10.10.200"
}

variable "dns" {
  type    = string
  default = "1.1.1.1"
}
variable "cpu_cores" {
  description = "Nombre de coeurs CPU "
  type        = number
  default     = 2
}

variable "memory" {
  description = "Mémoire vive de la VM "
  type        = number
  default     = 2048
}

variable "username" {
  description = "Utilisateur créé par cloud-init"
  type        = string
  default     = "ubuntu"
}
variable "network_bridge" {
  description = "connexion bridge de la vm"
  type        = string
  default     = "vmbr0"
}