resource "azurerm_network_interface" "elastic" {
  name                = "${var.env}-elastic-nic"
  location            = "${module.tooling.location}"
  resource_group_name = "${module.tooling.rg_name}"
  network_security_group_id = "${azurerm_network_security_group.elastic.id}"
 
  ip_configuration {
    name                          = "elastic"
    private_ip_address_allocation = "dynamic"
    subnet_id                     = "${module.tooling.main_subnet_id}"
  }
  tags {
    mvp         = "${var.mvp_name}"
    environment = "${var.env}"
  }
}
 
resource "azurerm_managed_disk" "disk_storage_elastic" {
  name                 = "disk_storage_elastic"
  location             = "${module.tooling.location}"
  resource_group_name  = "${module.tooling.rg_name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "${var.elastic_storage_disk_size_gb}"
}
 
data "template_file" "elastic-cloudinit" {
  template = "${file("core_cloud_init.tpl")}"
 
  vars {
    mount_path = "/var/lib/elastic"
  }
}
 
resource "azurerm_virtual_machine" "elastic" {
  location                      = "${module.tooling.location}"
  name                          = "${var.env}-elastic"
  network_interface_ids         = ["${azurerm_network_interface.elastic.id}"]
  resource_group_name           = "${module.tooling.rg_name}"
  vm_size                       = "${var.elastic_vm_size}"
  delete_os_disk_on_termination = true
 
  os_profile {
    admin_username = "ansible"
    computer_name  = "${var.env}elastic"
    custom_data = "${data.template_file.elastic-cloudinit.rendered}"
  }
 
  storage_os_disk {
    name              = "${var.env}-elastic-os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = 400
  }
 
  storage_data_disk {
    name            = "${azurerm_managed_disk.disk_storage_elastic.name}"
    managed_disk_id = "${azurerm_managed_disk.disk_storage_elastic.id}"
    create_option   = "Attach"
    lun             = 0
    disk_size_gb    = "${azurerm_managed_disk.disk_storage_elastic.disk_size_gb}"
  }
 
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
 
  os_profile_linux_config {
    disable_password_authentication = true
 
    ssh_keys {
      path     = "/home/ansible/.ssh/authorized_keys"
      key_data = "${var.ssh_key}"
    }
  }
  tags {
    mvp         = "${var.mvp_name}"
    environment = "${var.env}"
  }
}
 
resource "azurerm_network_security_group" "elastic" {
  name                = "${var.env}-elastic"
  location            = "${module.tooling.location}"
  resource_group_name = "${module.tooling.rg_name}"
  tags {
    mvp         = "${var.mvp_name}"
    environment = "${var.env}"
  }
}
 
resource "azurerm_network_security_rule" "elastic_ci_vnet_to_self_only" {
  name                        = "${var.env}-ci-vnet_to_self_only"
  priority                    = 150
  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "*"
  direction                   = "Inbound"
  network_security_group_name = "${azurerm_network_security_group.elastic.name}"
  protocol                    = "*"
  resource_group_name         = "${module.tooling.rg_name}"
  source_address_prefix       = "${var.tooling_address_space}"
  source_port_range           = "*"
}
 
resource "azurerm_network_security_rule" "elastic_ci_DenyAllInBound" {
  name                        = "${var.env}-ci-DenyAllInBound"
  priority                    = 151
  access                      = "Deny"
  destination_address_prefix  = "*"
  destination_port_range      = "*"
  direction                   = "Inbound"
  network_security_group_name = "${azurerm_network_security_group.elastic.name}"
  protocol                    = "*"
  resource_group_name         = "${module.tooling.rg_name}"
  source_address_prefix       = "*"
  source_port_range           = "*"
}
variable "elastic_storage_disk_size_gb" {
  default = 200
}
variable "elastic_vm_size" {
  default = "Standard_D4_v3"
}
output "elastic_private_ip" {
  value = "${azurerm_network_interface.elastic.private_ip_address}"
}
