variable "environment" {}
variable "resource_group" {}
variable "tags" {}
variable "vnet" {}
variable "subnet" {}

locals {
    keyvault_name = "kv-${var.environment.project_name}-${var.resource_group.location}"
    keyvault_pe_name   = "pe-${local.keyvault_name}"
    kv_DNS_Zone = "privatelink.vaultcore.azure.net"
}

data "azurerm_client_config" "current" {}

# Azure KeyVault
resource "azurerm_key_vault" "kv" {
  name                        = local.keyvault_name
  location                    = var.resource_group.location
  resource_group_name         = var.resource_group.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  tags                        = var.tags

  enable_rbac_authorization = true

  lifecycle {
    ignore_changes = [ tags ]
  }

  network_acls {
    bypass = "None"
    default_action = "Deny"
  }
}

# Azure KeyVault Private DNS Zone
resource "azurerm_private_dns_zone" "kv" {
  name                = local.kv_DNS_Zone
  resource_group_name = var.resource_group.name
}

# Azure KeyVault Private DNS Zone Virtual Network Link
resource "azurerm_private_dns_zone_virtual_network_link" "kv" {
  name                  = local.keyvault_pe_name
  resource_group_name   = var.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.kv.name
  virtual_network_id    = var.vnet.id
}

# Azure KeyVault Private Endpoint
resource "azurerm_private_endpoint" "kv" {
  name                              = local.keyvault_pe_name
  location                          = var.resource_group.location
  resource_group_name               = var.resource_group.name
  tags                              = var.tags

  lifecycle {
    ignore_changes                  = [tags]
  }

  subnet_id                         = var.subnet.id

  private_service_connection {
    name                            = local.keyvault_pe_name
    private_connection_resource_id  = azurerm_key_vault.kv.id
    is_manual_connection            = false
    subresource_names               = ["vault"]
  }

  private_dns_zone_group {
      name                 = "kv-private-dns-group"
      private_dns_zone_ids = [azurerm_private_dns_zone.kv.id]
  }
}
