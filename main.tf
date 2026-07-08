provider "azurerm" { 
 tenant_id   = var.tenant_id
 subscription_id = var.subscription_id
 # Prevents automatic registration of resource providers
 resource_provider_registrations = "none"
 features {} 
} 
# Create Storage Account 
resource "azurerm_storage_account" "sg1" { 
 name      =  "otstorageaccount" # add your name to make it unique. Can only consist of lowercase letters and numbers, and must be between 3 and 24 characters long.
 resource_group_name   =  var.rg_name
 location     =  var.location
 # Performance tier: Standard (HDD-backed)
 account_tier    =  "Standard" 
  # Replication strategy:
  # LRS = Locally Redundant Storage
 account_replication_type =  "LRS" 
 # Allows public access to blobs/containers
 allow_nested_items_to_be_public = true 
} 

# Create a Blob inside the Storage Account
resource "azurerm_storage_container" "newcontainer1" { 
 name     =  "container-json" 
 storage_account_id =  azurerm_storage_account.sg1.id
 # Access level: "blob"    = anonymous read access to blobs only
 container_access_type =  "blob" 
} 
# Create Storage Account 
resource "azurerm_storage_account" "sg2" { 
 name      =  "csestologs" # add your name to make it unique. Can only consist of lowercase letters and numbers, and must be between 3 and 24 characters long.
 resource_group_name   =  var.rg_name
 location     =  var.location
 # Performance tier: Standard (HDD-backed)
 account_tier    =  "Standard" 
  # Replication strategy:
  # LRS = Locally Redundant Storage
 account_replication_type =  "LRS" 
 # Allows public access to blobs/containers
 allow_nested_items_to_be_public = true 
}

# Create a Blob inside the Storage Account
resource "azurerm_storage_container" "newcontainer2" { 
 name     =  "container-logs" 
 storage_account_id =  azurerm_storage_account.sg2.id
 # Access level: "blob"    = anonymous read access to blobs only
 container_access_type =  "blob" 
} 
# Create MySQL Server 
resource "azurerm_mysql_flexible_server" "serverformation1" { 
name    =  "sqlserver" # add your name to make it unique. Can only consist of lowercase letters and numbers, and must be between 3 and 24 characters long.

location    =  var.location 
resource_group_name  =  var.rg_name  
administrator_login   =  "adminformation" 
administrator_password =  "formationCodingGame0!"
 sku_name =  "B_Standard_B1ms" 
 version =  "8.0.21" 
 geo_redundant_backup_enabled = false 
 storage { 
  auto_grow_enabled = false 
  size_gb = 20 
  io_scaling_enabled = false 
  iops = 360
  }
} 
resource "azurerm_mysql_flexible_server_configuration" "ssl_config" {
  name                = "require_secure_transport"
  resource_group_name = var.rg_name
  server_name         = azurerm_mysql_flexible_server.serverformation1.name
  value               = "OFF"
}
# Create MySQL database 
resource "azurerm_mysql_flexible_database" "mysqldb1" { 
 name    =  "mysqldb1-iac" 
 resource_group_name =  var.rg_name
 server_name   =  azurerm_mysql_flexible_server.serverformation1.name
 charset    =  "utf8" 
 collation    =  "utf8_unicode_ci" 
 depends_on = [ azurerm_mysql_flexible_server.serverformation1 ] 
} 
# Configure firewall to open access 
resource "azurerm_mysql_flexible_server_firewall_rule" "mysqlfwrule1" { 
 name        =  "mysqlfwrule1-iac" 
 resource_group_name =  var.rg_name
 server_name     =  azurerm_mysql_flexible_server.serverformation1.name 
 start_ip_address  =  "0.0.0.0"
 end_ip_address   =  "255.255.255.255" 
 depends_on = [ azurerm_mysql_flexible_server.serverformation1, 
 azurerm_mysql_flexible_database.mysqldb1 ] 
}
# Create a Virtual Network
resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1-iac"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.rg_name

  subnet {
    name             = "subnet1-iac"
    address_prefixes = ["10.0.1.0/24"]
  }
}
# Create a public IP
resource "azurerm_public_ip" "publicIP1" {
  name                = "publicIP1-iac"
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "Standard"
  allocation_method   = "Static"
}
# Define a network interface for the VM 
resource "azurerm_network_interface" "nic1" {
  name                = "nic1-iac"
  location            = var.location
  resource_group_name = var.rg_name
  ip_configuration {
    name                          = "ipconfig1-iac"
    subnet_id                     = azurerm_subnet.subnet1[count.index].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicIP1[count.index].id
  }
}
# Define security group 
resource "azurerm_network_security_group" "nsg1" {
  name                = "nsg1-iac"
  location            = var.location
  resource_group_name = var.rg_name

  security_rule {
    name                        = "HTTP"
    priority                    = 1010
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "*"
    source_port_range           = "*"
    destination_port_range      = "80"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
  }

  security_rule {
    name                        = "HTTPS"
    priority                    = 1009
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "*"
    source_port_range           = "*"
    destination_port_range      = "443"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
  }

  security_rule {
    name                        = "SSH"
    priority                    = 1008
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "*"
    source_port_range           = "*"
    destination_port_range      = "22"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
  }
}
# Assign the security group to the network interface 
resource "azurerm_network_interface_security_group_association" "association1" {
  network_interface_id      = azurerm_network_interface.nic1[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg1[count.index].id
}
# Create Virtual Machine
resource "azurerm_linux_virtual_machine" "vm-website" {
  name                            = "vm-website" # add your name to make it unique. Can only consist of lowercase letters and numbers, and must be between 3 and 24 characters long.
  location                        = var.location
  resource_group_name             = var.rg_name
  network_interface_ids           = [azurerm_network_interface.nic1[count.index].id]
  size                            = "Standard_B1ls"
  admin_username                  = "user-formation"
  admin_password                  = "formationCodingGame0!"
  disable_password_authentication = false

  source_image_reference {
    publisher = "canonical"
    offer     = "ubuntu-26_04-lts"
    sku       = "server"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}