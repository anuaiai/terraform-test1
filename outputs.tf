/*
output "private_ip" {
  description = "private ip address of compute"
  value       = "${azurerm_network_interface.nic.private_ip_address}"
} 
*/

 output "application_security_group_id" {
   description = "id of the security group provisioned"
   value       = "${azurerm_application_security_group.asg.id}"
 }

 output "network_security_group_id" {
   description = "id of the security group provisioned"
   value       = "${azurerm_network_security_group.nsg.id}"
 }

/*
output "network_interface_ids" {
  description = "ids of the vm nics provisoned."
  value       = "${azurerm_network_interface.nic.*.id}"
}
*/