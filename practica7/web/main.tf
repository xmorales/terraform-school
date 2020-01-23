resource "azurerm_network_security_group" "web" {
  name                = "${var.resource_group}-web"
  location            = var.location
  resource_group_name = var.resource_group

  security_rule {
    name                       = "allow-www"
    description                = "Allow HTTP Traffic"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-internal-ssh"
    description                = "Allow Internal SSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet" "web" {
  name                 = "${var.resource_group}-web"
  virtual_network_name = var.virtual_network
  resource_group_name  = var.resource_group
  address_prefix       = "10.0.1.0/24"
}

resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}

resource "azurerm_availability_set" "avset" {
  name                         = "${var.dns_name}avset"
  location                     = var.location
  resource_group_name          = var.resource_group
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

resource "azurerm_public_ip" "lbpip" {
  name                = "${var.prefix}-ip"
  location            = var.location
  resource_group_name = var.resource_group
  allocation_method   = "Dynamic"
  # domain_name_label   = var.lb_ip_dns_name
}

resource "azurerm_lb" "lb" {
  resource_group_name = var.resource_group
  name                = "${var.prefix}lb"
  location            = var.location

  frontend_ip_configuration {
    name                 = "LoadBalancerFrontEnd"
    public_ip_address_id = azurerm_public_ip.lbpip.id
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  resource_group_name = var.resource_group
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "BackendPool1"
}

resource "azurerm_lb_rule" "lb_rule" {
  resource_group_name            = var.resource_group
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "LBRule"
  protocol                       = "tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  enable_floating_ip             = false
  backend_address_pool_id        = azurerm_lb_backend_address_pool.backend_pool.id
  idle_timeout_in_minutes        = 5
  probe_id                       = azurerm_lb_probe.lb_probe.id
  depends_on                     = [azurerm_lb_probe.lb_probe]
}

resource "azurerm_lb_probe" "lb_probe" {
  resource_group_name = var.resource_group
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "tcpProbe"
  protocol            = "tcp"
  port                = 80
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_network_interface" "nic" {
  name                = "nic${count.index}"
  location            = var.location
  resource_group_name = var.resource_group
  count               = 2

  ip_configuration {
    name                                    = "ipconfig${count.index}"
    subnet_id                               = azurerm_subnet.web.id
    private_ip_address_allocation           = "Dynamic"
    load_balancer_backend_address_pools_ids = [azurerm_lb_backend_address_pool.backend_pool.id]
  }
}

resource "azurerm_virtual_machine" "vm" {
  name                  = "vm${count.index}"
  location              = var.location
  resource_group_name   = var.resource_group
  availability_set_id   = azurerm_availability_set.avset.id
  vm_size               = var.web_size
  network_interface_ids = [element(azurerm_network_interface.nic.*.id, count.index)]
  count                 = 2

  storage_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  storage_os_disk {
    name          = "osdisk${count.index}"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = var.hostname
    admin_username = var.admin_username
    admin_password = var.admin_password
    custom_data    = ""
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
