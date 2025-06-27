variable "region" {
  type    = string
  default = "eastus"
}

variable "application" {
  type = string
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "st_account_tier" {
  type    = string
  default = "Standard"
}

variable "st_account_replication_type" {
  type    = string
  default = "LRS"
}

variable "base_address_space" {
  type = set(string)
}

variable "admin_username" {
  type = string
}

variable "admin_password" {
  type = string
}

variable "public_ssh_key_path" {
  type = string
}

variable "common_tags" {
  type = map(string)
  default = {
    environment = "dev"
    owner       = "IT"
    project     = "ConfigMgmt-POC"
  }
}

