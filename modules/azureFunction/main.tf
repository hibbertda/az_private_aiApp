# Variables
variable "environment" {}
variable "resource_group" {}
variable "tags" {}
variable "vnet" {}
variable "subnet" {}
variable "int_subnet" {}

locals {
  storageaccount_name = "0jqdfunctionapp"
  storageDNSZone_name = "privatelink.blob.core.windows.net"
  servicePlan_name = "asp-${var.environment.project_name}-${var.resource_group.location}"
  functionApp_name = "func-${var.environment.project_name}-${var.resource_group.location}"
  webSites_DNSZone = "privatelink.azurewebsites.net" #Common for ASP hosted services
}

resource "azurerm_storage_account" "storage" {
  name                     = local.storageaccount_name
  resource_group_name      = var.resource_group.name
  location                 = var.resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags

  lifecycle {
    ignore_changes = [ tags ]
  }

  network_rules {
    default_action = "Deny"
  }
}

# Azure Private DNS for Storage Account
resource "azurerm_private_dns_zone" "storage" {
  name                = local.storageDNSZone_name
  resource_group_name = var.resource_group.name

  lifecycle {
    ignore_changes = [ tags ]
  }
}

# Azure Private DNS for Storage Account Virtual Network Link
resource "azurerm_private_dns_zone_virtual_network_link" "storage" {
  name                  = "dnslink-${local.storageaccount_name}"
  resource_group_name   = var.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.storage.name
  virtual_network_id    = var.vnet.id

  lifecycle {
    ignore_changes = [ tags ]
  }
}

# Storage Account Private Endpoint
resource "azurerm_private_endpoint" "storage" {
  name                = "pe-${local.storageaccount_name}"
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  tags                = var.tags

  lifecycle {
    ignore_changes = [tags]
  }

  subnet_id           = var.subnet.id

  private_service_connection {
    name                           = "storage-private-connection"
    private_connection_resource_id = azurerm_storage_account.storage.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
    private_dns_zone_group {
    name                 = "funcstore-private-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage.id]
  }
}

# Azure AppService Plan
resource "azurerm_service_plan" "asp" {
  name                = local.servicePlan_name
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
  os_type             = "Linux"
  sku_name            = "P1v2"

  lifecycle {
    ignore_changes = [ tags ]
  }
}

# Azure Function App
resource "azurerm_linux_function_app" "func" {
  name                = local.functionApp_name
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location

  storage_account_name       = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key
  service_plan_id            = azurerm_service_plan.asp.id

  public_network_access_enabled = false
  virtual_network_subnet_id = var.int_subnet.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    vnet_route_all_enabled = true # Route all outbound traffic from the function app through the VNET
    application_stack {
      python_version = "3.12"
    }
  }

  lifecycle {
    ignore_changes = [ tags ]
  }
}

# Function App: Private DNS Zone Virtual
resource "azurerm_private_dns_zone" "func_dns" {
  name                = local.webSites_DNSZone
  resource_group_name = var.resource_group.name

  lifecycle {
    ignore_changes = [ tags ]
  }
}
# Function App: Private DNS Zone VNET Link
resource "azurerm_private_dns_zone_virtual_network_link" "func_dns_link" {
  name                  = local.webSites_DNSZone
  resource_group_name   = var.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.func_dns.name
  virtual_network_id    = var.vnet.id

  lifecycle {
    ignore_changes = [ tags ]
  }
}

# Function App: Private Endpoint
resource "azurerm_private_endpoint" "func" {
  name                = "pe-${local.functionApp_name}"
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  tags                = var.tags

  lifecycle {
    ignore_changes = [tags]
  }

  subnet_id           = var.subnet.id

  private_service_connection {
    name                           = "func-private-connection"
    private_connection_resource_id = azurerm_linux_function_app.func.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }
  private_dns_zone_group {
    name                 = "funcstore-private-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.func_dns.id]
  }
}


