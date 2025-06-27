variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "rg-custom-metrics-lab"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "West Europe"
}

variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "custom-metrics-lab"
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "stage" {
  description = "Environment stage (dev, prelive, live)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "prelive", "live"], var.stage)
    error_message = "Stage must be one of: dev, prelive, live."
  }
}

variable "target_domain" {
  description = "Domain to monitor with DNS queries"
  type        = string
  default     = "example.com"
}