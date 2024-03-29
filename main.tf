# Configuration to the microsoft provider
#provider "azurerm" {
# subscription_id = "8226e4e3-01f5-4079-a39e-2ed6195f85bf"
# client_id = "dc692473-5572-45bc-8676-c23525105765"
# tenant_id = "a7dc1825-78a5-4758-8f80-cad8e137a7f5"
# client_secret = "dY[h03XFNeEc.i2YP4wNgktpgRxkfn/?"
#}
# Creating the resource groupin azure
resource "azurerm_resource_group" "safeway" {
name = "SafewayGroup"
location = "West Us"
}
resource "azurerm_virtual_network" "test" {
  name                = "acceptanceTestVirtualNetwork1"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.safeway.location}"
  resource_group_name = "${azurerm_resource_group.safeway.name}"
}

resource "azurerm_subnet" "test" {
  name                 = "testsubnet"
  resource_group_name  = "${azurerm_resource_group.safeway.name}"
  virtual_network_name = "${azurerm_virtual_network.test.name}"
  address_prefix       = "10.0.2.0/24"
}
#data "azurerm_subnet" "test" {
#name = "default"
#virtual_network_name = "SafewayVnet"
#resource_group_name = "Albertson"
#}
resource "azurerm_network_security_group" "safewaysecurity" {
name = "SafewaySecurityGroup"
location = "West Us"
resource_group_name = "${azurerm_resource_group.safeway.name}"
security_rule {
name = "SSH"
priority = 1001
direction = "Inbound"
access = "Allow"
protocol = "Tcp"
source_port_range = "*"
destination_port_range = "22"
source_address_prefix = "*"
destination_address_prefix = "*"
}
}
resource "azurerm_network_interface" "safeway" {
name = "Safewayinterface"
location = "West US"
resource_group_name = "${azurerm_resource_group.safeway.name}"
network_security_group_id = "${azurerm_network_security_group.safewaysecurity.id}"
ip_configuration {
name = "SafewayConfig"
subnet_id = "${azurerm_subnet.test.id}"
private_ip_address_allocation = "Dynamic"
}
}
resource "azurerm_virtual_machine" "testvm" {
name = "SafewayVm"
location = "West Us"
resource_group_name = "${azurerm_resource_group.safeway.name}"
network_interface_ids = ["${azurerm_network_interface.safeway.id}"]
vm_size = "Standard_D1"
count = "1"
storage_os_disk {
name = "SafewayDisk"
caching = "ReadWrite"
create_option = "FromImage"
  }

storage_image_reference {
publisher = "OpenLogic"
offer = "CentOS"
sku = "7.5"
version = "latest"
}
os_profile {
computer_name = "Albertson"
admin_username = "safeway"
admin_password = "safeway@123"
}
os_profile_linux_config {
disable_password_authentication = false
}
connection {
type = "ssh"
host = "${azurerm_network_interface.safeway.private_ip_address}"
user = "safeway"
port = "22"
agent = false
}
}
resource "null_resource" "null" {
provisioner "file" {
connection {
type = "ssh"
user = "safeway"
password = "safeway@123"
host = "${azurerm_network_interface.safeway.private_ip_address}"
}
#source  = "install.bash"
source = "install.bash"
destination = "/tmp/install.bash"
}

connection {
type = "ssh"
user = "safeway"
password = "safeway@123"
host = "${azurerm_network_interface.safeway.private_ip_address}"
}
# Configure Puppet
provisioner "remote-exec" {
    inline = [
      "cp /etc/hosts /tmp/hosts",
      "echo '10.0.1.6  puppetmaster.sxkoxi1m2bqujhxq4i00de5lbb.dx.internal.cloudapp.net' >> /tmp/hosts", 
      "echo 'safeway@123'|sudo -S cp /tmp/hosts /etc/hosts", 
      "echo 'safeway@123'| sudo -S chmod 777 /tmp/install.bash", 
      "echo 'safeway@123'| sudo -S yum install puppet-agent -y", 
      "echo 'safeway@123'| sudo -S bash /tmp/install.bash"
    ]
  }
  }
