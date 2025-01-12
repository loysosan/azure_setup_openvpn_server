resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.vm_name}-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "main" {
  name                 = "${var.vm_name}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "vm_openvpn_public_ip" {
  name                = "${var.vm_name}-vm-openvpn-public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Basic"
}

resource "azurerm_network_interface" "openvpn_nic" {
  name                = "${var.vm_name}-openvpn-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {  
    name                          = "openvpn-config"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_openvpn_public_ip.id
    subnet_id                     = azurerm_subnet.main.id
  }
}

resource "azurerm_linux_virtual_machine" "vm_openvpn" {
  name                            = "${var.vm_name}-vm-openvpn"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = var.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  network_interface_ids = [azurerm_network_interface.openvpn_nic.id]

  tags = {
    environment = "Production"
  }
  custom_data = base64encode(templatefile(var.custom_data_path, {
    vpn_server_public_ip  = azurerm_public_ip.vm_openvpn_public_ip.ip_address
    vpn_server_url  = var.vpn_domain_name
  }))
}

