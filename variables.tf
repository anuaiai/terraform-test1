###### General ######


variable "environment" {
  type        = "string"
  description = "The environment name"
}


variable "location" {
  type = "string"
  description = "The Location for Infra centre"
  default     = "northeurope"
}


##### Global Variable #####

### Tags

##############################################
#### global variable ###
##############################################
variable "app_name" {
  type = "string"
  description = "Application name of IFRS project"
  default = "sas"
}

variable "costcenter" {
  type = "string"
  description = "The cost_center name for this porject"
  default = "ifrs"
}

variable "company" {
  type = "string"
  description = "The cost_center name for this porject"
  default = "Atradius"
}

variable "department" {
  type = "string"
  description = "The cost_center name for this porject"
  default = "ITS"
}
variable "owner" {
  type = "string"
  description = "The name of the infra provisioner or owner"
  default = "Prem"
}

###### Network ######

### Vnet
variable "vnet_name" {
    description = "The Pub key for accessing the VM"
}

variable "vnet_rg_name" {
    description = "The Pub key for accessing the VM"
}

### Subnet
variable "subnet_name" {
    description = "The Pub key for accessing the VM"
}

###### Compute ######
variable "username" {
  type = "string"
  description = "The root user name for the compute resource"
}

variable "sas-vm-user-data"{
    description = "The custom init script"
}

variable "sas-vm-size" {
  type = map
  description = "The Size for vm resource"
}

variable "ssh-public-key" {
    description = "The Pub key for accessing the VM"
}


### Network rule ###

### Inbound

variable "rule_portrange"{
    description = "The Pub key for accessing the VM"
}
variable "rule_name" {
   type = list(string)
   description = "Names of the rules"
}
variable "rule_description" {
   type = list(string)
   description = "Short description for the rule"
}

### Outbound

variable "outbound_rule_portrange" {
  type = list(number)
  description = "Define the port need to be opened for outbound"
}
variable "outbound_rule_name" {
   type = list(string)
   description = "Names of the outbound rules"

}
variable "outbound_rule_description" {
  type = list(string)
  description = "Short description for the outbound rule"
}