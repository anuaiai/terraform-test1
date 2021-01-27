##################################################
# Providers
##################################################

provider "azurerm" {
  version = ">=2.5.0"
  features {}
}

##################################################
# locals for taging
##################################################

locals {
  Owner       = "${var.owner}"
  Environment = "${var.environment}"
  CostCenter = "${var.costcenter}"
  Company     = "${var.company}"
  Application = "${var.app_name}"
  Department  = "${var.department}"
}

locals {
  common_tags = {
    Owner       = local.Owner
    Environment = local.Environment
    CostCenter  = local.CostCenter
    Company     = local.Company
    Application = local.Application
    Department  = local.Department
  }
}

###################################################
# Azure Resource Group
###################################################

resource "azurerm_resource_group" "rg" {
  name     = "${var.environment}-${var.location}-${var.app_name}-rg"
  location = "${var.location}"
  tags     = "${local.common_tags}"
}

##################################################
# Azure Vnet
##################################################

data "azurerm_virtual_network" "vnet" {
  name                = "${var.vnet_name}"
  resource_group_name = "${var.vnet_rg_name}"
  
}

##################################################
# Azure Subnet
##################################################

data "azurerm_subnet" "subnet" {
  name                 = "${var.subnet_name}"
  virtual_network_name = "${data.azurerm_virtual_network.vnet.name}"
  resource_group_name = "${data.azurerm_virtual_network.vnet.resource_group_name}"
  
}

##################################################
# # Azure SAS Compute NIC
##################################################

resource "azurerm_network_interface" "sas_nic" {
  for_each = "${var.sas-vm-size}"
  name                = "sas-${each.key}-vm-nic"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  enable_ip_forwarding = false
  ip_configuration {
    name = "internal"
    private_ip_address_allocation = "Dynamic"
    subnet_id = "${data.azurerm_subnet.subnet.id}"
     }
  tags     = "${local.common_tags}"
  }

##################################################
# Application security group
##################################################

resource "azurerm_application_security_group" "asg" {
  name                = "sas-${var.environment}-asg"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  tags = "${local.common_tags}"
}

##################################################
# Network security group
##################################################

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.environment}-${var.app_name}-nsg"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${var.location}"
  tags = "${local.common_tags}"
}

##################################################
# Network security rules
##################################################

resource "azurerm_network_security_rule" "rules" {
  count = "${length(var.rule_portrange)}"
  name = element(var.rule_name, count.index)
  direction = "Inbound"
  description = element(var.rule_description, count.index)
  source_port_range                          = "*"
  destination_port_range = element(var.rule_portrange, count.index)
  source_address_prefix                      = "*"
  destination_application_security_group_ids = [azurerm_application_security_group.asg.id]
  protocol = "Tcp"
  access = "Allow"
  priority = "${(count.index + 10) * 10}"
  resource_group_name                        = "${azurerm_resource_group.rg.name}"
  network_security_group_name                = "${azurerm_network_security_group.nsg.name}"
}


resource "azurerm_network_security_rule" "rules_outbound" {
  count = "${length(var.outbound_rule_portrange)}"
  name = element(var.outbound_rule_name, count.index)
  direction = "Outbound"
  description = element(var.outbound_rule_description, count.index)
  source_port_range                          = "*"
  destination_port_range = element(var.outbound_rule_portrange, count.index)
  source_address_prefix                      = "*"
  destination_address_prefix = "*"
  protocol = "Tcp"
  access = "Allow"
  priority = "${(count.index + 11) * 11}"
  resource_group_name                        = "${azurerm_resource_group.rg.name}"
  network_security_group_name                = "${azurerm_network_security_group.nsg.name}"
}

##################################################
# NSG adding to Subnet
##################################################

resource "azurerm_subnet_network_security_group_association" "nsg_subnet" {
  subnet_id                 = "${data.azurerm_subnet.subnet.id}"
  network_security_group_id = "${azurerm_network_security_group.nsg.id}"
}

##################################################
# Azure SAS
##################################################

resource "azurerm_linux_virtual_machine" "sas_vm" {
  for_each = "${var.sas-vm-size}"
  name                = "sas-${each.key}-vm"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  admin_username        = "${var.username}"
  network_interface_ids = ["${azurerm_network_interface.sas_nic[each.key].id}"]
  custom_data           = base64encode(var.sas-vm-user-data)
  size = "${each.value}"
  zone                  = 1
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "7-RAW-CI"
    version   = "7.6.2019072418"
  }
  tags     = "${local.common_tags}"

  admin_ssh_key {
    username = "${var.username}"
    public_key = "${var.ssh-public-key}"
  }
  additional_capabilities {
    ultra_ssd_enabled = false
  }
 # os_profile_linux_config {
 #   disable_password_authentication = false
 # }
}

##################################################
# Azure SAS VM Extension
##################################################

resource "azurerm_virtual_machine_extension" "sas_vm_extension" {
  for_each = "${var.sas-vm-size}"
  name                       = "sas-${each.key}-vm"
  virtual_machine_id         = "${azurerm_linux_virtual_machine.sas_vm[each.key].id}"
  publisher                  = "Microsoft.Azure.ActiveDirectory.LinuxSSH"
  type                       = "AADLoginForLinux"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
}