resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

locals {
  public_ssh_key = tls_private_key.example.public_key_openssh
}

resource "azurerm_network_security_group" "bastion" {
  name                = "${var.resource_group}-mgmt-nsg"
  location            = var.location
  resource_group_name = var.resource_group

  security_rule {
    name                       = "allow-ssh"
    description                = "Allow SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet" "bastion" {
  name                 = "${var.resource_group}-bastion"
  virtual_network_name = var.virtual_network
  resource_group_name  = var.resource_group
  address_prefix       = "10.0.0.128/25"
}

resource "azurerm_subnet_network_security_group_association" "bastion" {
  subnet_id                 = azurerm_subnet.bastion.id
  network_security_group_id = azurerm_network_security_group.bastion.id
}

locals {
  virtual_machine_name = "${var.resource_group}-bastion"
  admin_username       = "testadmin"
}

resource "azurerm_network_interface" "example" {
  name                = "${var.resource_group}-nic"
  location            = var.location
  resource_group_name = var.resource_group
  # network_security_group_id = azurerm_network_security_group.bastion.id

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.bastion.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id
  }
}

resource "azurerm_public_ip" "example" {
  name                = "${var.resource_group}-bastionpip"
  location            = var.location
  resource_group_name = var.resource_group
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_machine" "example" {
  name                  = local.virtual_machine_name
  location              = var.location
  resource_group_name   = var.resource_group
  network_interface_ids = [azurerm_network_interface.example.id]
  vm_size               = "Standard_B1s"

  storage_image_reference {
    publisher = "MicrosoftOSTC"
    offer     = "FreeBSD"
    sku       = "11.1"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${local.virtual_machine_name}-osdisk"
    managed_disk_type = "Standard_LRS"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  os_profile {
    computer_name  = local.virtual_machine_name
    admin_username = local.admin_username
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${local.admin_username}/.ssh/authorized_keys"
      key_data = local.public_ssh_key
    }
  }
}
