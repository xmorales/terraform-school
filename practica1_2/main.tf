provider "azurerm" {
  version = "~> 1.40"
}

# Create a resource group
resource "azurerm_resource_group" "p1" {
  name     = "practica1"
  location = "West Europe"

}
