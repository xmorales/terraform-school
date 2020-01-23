resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-resources"
  location = var.location
}

resource "azurerm_virtual_network" "vnetwork" {
  name                = "${var.prefix}-network"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

module "bastion" {
  source          = "./bastion"
  location        = var.location
  resource_group  = azurerm_resource_group.rg.name
  virtual_network = azurerm_virtual_network.vnetwork.name
}

module "web" {
  source          = "./web"
  location        = var.location
  resource_group  = azurerm_resource_group.rg.name
  virtual_network = azurerm_virtual_network.vnetwork.name
  admin_password  = var.admin_password
  hostname        = var.hostname
  prefix          = var.prefix
}
