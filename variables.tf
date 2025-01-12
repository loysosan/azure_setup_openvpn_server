############# Subscription ID Credentials ############
variable "tenant_id" {
  type        = string
  description = "The Azure tenant ID."
}

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID."
}

variable "client_id" {
  type        = string
  description = "The Azure client ID."
}

variable "client_secret" {
  type        = string
  description = "The Azure client secret."
}

############# Location ######################
variable "location" {
  type        = string
  description = "The Azure region to deploy resources into."
  default     = "Germany West Central"
}

############ Resource Group Name ############
variable "resource_group_name" {
  type        = string
  description = "The name of the Resource Group."
}

############ Virtual Machine ############
variable "vm_name" {
  type = string
}

variable "admin_username_vm" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "vm_size_openvpn" {
  type = string
  default = "Standard_B1s"
}


