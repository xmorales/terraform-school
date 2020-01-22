provider "azurerm" {
  version = "~> 1.40"
}

# Create a resource group
resource "azurerm_resource_group" "practica1" {
  name     = "practica1"
  location = "North Europe"
}
