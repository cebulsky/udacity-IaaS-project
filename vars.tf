variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
  default = "website"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  default = "westeurope"
}

variable "username" {
  description = "User Name for virtual machine"
  default = "udacity"
}

variable "password" {
  description = "Password for virtual machine user"
}

variable "project_name" {
  description = "project name to be used in resources tags"
  default = "udacity-web-app"
}

variable "virtual_machines_count" {
  description = "Number of virtual machines (1 application instance per VM) under Load Balancer"
  type = number
  default = 2
  validation {
    condition     = var.virtual_machines_count >= 2 && var.virtual_machines_count <= 5
    error_message = "Number of virtual machines should be between 2 and 5."
  }
}