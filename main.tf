
resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

data "azurerm_client_config" "current" {

}

locals {
  alpha_address_space   = cidrsubnet(one(var.base_address_space), 2, 0)
  bravo_address_space   = cidrsubnet(one(var.base_address_space), 2, 1)
  charlie_address_space = cidrsubnet(one(var.base_address_space), 2, 2)
  delta_address_space   = cidrsubnet(one(var.base_address_space), 2, 3)
}

# Generate SSH key pair for VM access
resource "tls_private_key" "linux_vm_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

// Create a Resource Group
module "avm-res-resources-resourcegroup" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.2.1"
  # Required Input 
  name     = "rg-${var.application}-${var.environment}"
  location = var.region
  # Optional Input
  # tags = var.common_tags
}

//Create a Storage Account
module "avm-res-storage-storageaccount" {
  source = "Azure/avm-res-storage-storageaccount/azurerm"
  // source = "git::https://github.com/gopalr66/terraform-azurerm-avm-res-storage-storageaccount.git?ref=main"
  version = "0.6.3"
  # Required Input - 3
  name                = "st${lower(var.application)}${random_string.suffix.result}"
  resource_group_name = module.avm-res-resources-resourcegroup.name
  location            = var.region
  # Optional Input
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  shared_access_key_enabled = true
  managed_identities = {
    system_assigned = true
  }

}

/*
resource "azurerm_storage_account" "cmpoc" {
  name                      = "st${lower(var.application)}${random_string.suffix.result}"
  resource_group_name       = module.avm-res-resources-resourcegroup.name
  location                  = var.region
  account_tier              = var.st_account_tier
  account_replication_type  = var.st_account_replication_type
  shared_access_key_enabled = false
  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = var.environment
  }
}
*/

// Create a Key Vault
module "avm-res-keyvault-vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.0"
  # Required input - 4
  name                = "kv-${var.application}-${var.environment}-${random_string.suffix.result}"
  location            = var.region
  resource_group_name = module.avm-res-resources-resourcegroup.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  # Optional input
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  sku_name                   = "standard"

}

// Create a Virtual Network
module "avm-res-network-virtualnetwork" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.8.1"
  # Required input - 3
  location            = var.region
  resource_group_name = module.avm-res-resources-resourcegroup.name
  address_space       = var.base_address_space
  # Optional input
  name = "vnet-${var.application}-${var.environment}"
}

// Create Subnets
module "avm-res-network-virtualnetwork_subnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm//modules/subnet"
  version = "0.9.0"
  # insert the 2 required variables here
  name            = "snet-alpha"
  virtual_network = module.avm-res-network-virtualnetwork
  address_prefix  = local.alpha_address_space
}

/*
// Create Network Interface
module "avm-res-network-networkinterface" {
  source  = "Azure/avm-res-network-networkinterface/azurerm"
  version = "0.1.0"
  # insert the 4 required variables here
  name = "nic-${var.application}-${var.environment}-${random_string.suffix.result}"
  location = var.region
  resource_group_name = module.avm-res-resources-resourcegroup.name
  ip_configurations = {
    "ipconfig1" = {
      name = "ipconfig1"
      subnet_id = module.avm-res-network-virtual_network-subnet.subnet_id
      private_ip+address_allocation = "Dynamic"
    }
  }
}
*/

// Create a Windows VM
module "avm-res-compute-virtualmachine-win" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.19.3"
  # insert the 5 required variables here
  name                = "vm-${var.application}-${var.environment}-01"
  location            = var.region
  resource_group_name = module.avm-res-resources-resourcegroup.name
  zone                = "1"
  os_type             = "Windows"
  sku_size            = "Standard_B1ls"
  admin_username      = var.admin_username
  admin_password      = var.admin_password


  network_interfaces = {
    "nic1" = {
      name      = "nic-${var.application}-${var.environment}-${random_string.suffix.result}"
      subnet_id = module.avm-res-network-virtualnetwork_subnet.resource_id
      ip_configurations = {
        "ipconfig1" = {
          name                          = "ipconfig1"
          private_ip_address_allocation = "Dynamic"
        }
      }
    }
  }

  /*
  network_interface_ids = [
    module.avm-res-network-network_interface.name.id
  ]
*/

  source_image_reference = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter"
    version   = "latest"
  }

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }


}

// Create a Linux VM
module "avm-res-compute-virtualmachine-linux" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.19.3"
  # insert the 5 required variables here
  name                = "vm-${var.application}-${var.environment}-${random_string.suffix.result}"
  location            = var.region
  resource_group_name = module.avm-res-resources-resourcegroup.name

  os_type  = "Linux"
  sku_size = "Standard_B1ls"
  zone     = "1"

  account_credentials = {
    ssh_keys = [
      {
        username   = var.admin_username
        public_key = tls_private_key.linux_vm_ssh_key.public_key_openssh
      }
    ]
  }


  network_interfaces = {
    "nic1" = {
      name      = "vm-linux-nic"
      subnet_id = module.avm-res-network-virtualnetwork_subnet.id
      ip_configurations = {
        "ipconfig1" = {
          name                          = "ipconfig1"
          private_ip_address_allocation = "Dynamic"
        }
      }
    }
  }


  source_image_reference = {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

}
