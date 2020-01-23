provider "azurerm" {
  version = "~> 1.40"
}

# Create a resource group
resource "azurerm_resource_group" "practica" {
  name     = "practica6"
  location = "West Europe"
}

output "resource_group_creado" {
  value = azurerm_resource_group.practica.name
}
