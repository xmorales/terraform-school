variable "resource_group" {
  description = "The resource group name used for all resources in this example"
}

variable "location" {
  description = "The Azure Region in which the resources in this example should exist"
  default     = "North Europe"
}

variable "virtual_network" {
  description = "The Virtual Network name to attach subnet"
  default     = "North Europe"
}
