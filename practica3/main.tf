provider "azurerm" {
  version = "~> 1.40"
}

locals {
  prefix = "p3"
}
# Create a resource group
resource "azurerm_resource_group" "practica" {
  name     = "${local.prefix}_RG"
  location = "North Europe"
}

output "resource_group_name" {
  value = azurerm_resource_group.practica
}
