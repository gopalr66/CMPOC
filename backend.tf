terraform {
  backend "azurerm" {
    resource_group_name  = "rg-CM_POC-tfstate"
    storage_account_name = "stcmpoctfstate001"
    container_name       = "cmpoc-tfstate"
    key                  = "infra.terraform.cmpoc-tfstate"
  }
}
