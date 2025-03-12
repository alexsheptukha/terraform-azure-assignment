provider "azurerm" {
  features {}
  subscription_id=var.subscription_id
}

terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = var.tfstate_storage_account_name
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
