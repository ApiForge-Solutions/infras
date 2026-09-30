variable "virtual_environment_node_name" {
  description = "Nom du node Proxmox"
  type        = string
}
variable "name" {
  type = string
}

variable "vm_id" {
  type = number
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

variable "ssh_public_key" {
  description = "Cle publique de la VM"
  type        = string
  sensitive   = true
}

variable "network_bridge" {
  description = "connexion bridge de la vm"
  type        = string
  default     = "vmbr0"
}
variable "disk_datastore_id" {
  type        = string
  description = "disk datastore"
}
variable "ubuntu_image_id" {
  type = string
}
variable "password" {
  description = "Mot de passe de l'utilisateur Ubuntu"
  type        = string
  sensitive   = true
}
