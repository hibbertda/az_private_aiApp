# terraform providers for Azure governemt cloud
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.39.1"
    }
  }
}

provider "azurerm" {
  features {}
  use_msi = false
  subscription_id = "<subscription id>"
}