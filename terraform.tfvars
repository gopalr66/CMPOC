region                      = "eastus"
application                 = "CMPOC"
environment                 = "dev"
st_account_tier             = "Standard"
st_account_replication_type = "LRS"
common_tags = {
  owner   = "IT"
  project = "ConfigMgmt-POC"
}

base_address_space  = ["10.40.0.0/22"]
admin_username      = "azureadmin"
admin_password      = "Ch@ng3Mgm+P0C"
public_ssh_key_path = "~/.ssh/id_vm1.pub"
