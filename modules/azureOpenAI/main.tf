variable "environment" {}
variable "resource_group" {}
variable "tags" {}
variable "vnet" {}
variable "subnet" {}
variable "func_MSI" {}
variable "functionApp"{}


locals {
    AzOpenAI_name = "openai-${var.environment.project_name}-${var.resource_group.location}"
    AzOpenAI_pe_name   = "pe-${local.AzOpenAI_name}"
    cogService_DNS_Zone = "privatelink.openai.azure.com"
}

# Azure OpenAI
resource "azurerm_cognitive_account" "openai" {
  name                    = local.AzOpenAI_name
  location                = var.resource_group.location
  resource_group_name     = var.resource_group.name
  kind                    = "OpenAI"
  sku_name                = "S0"
  custom_subdomain_name   = "openai-pet"
  tags                    = var.tags

  lifecycle {
    ignore_changes = [ tags ]
  }

  # Disbale public network access
  public_network_access_enabled = false
}

# Azure OpenAI Private DNS Zone
resource "azurerm_private_dns_zone" "openai" {
  name                = local.cogService_DNS_Zone
  resource_group_name = var.resource_group.name

  lifecycle {
    ignore_changes = [ tags ]
  }
}

# Azure OpenAI Private DNS Zone Virtual Network Link
resource "azurerm_private_dns_zone_virtual_network_link" "openai" {
  name                  = local.AzOpenAI_pe_name
  resource_group_name   = var.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.openai.name
  virtual_network_id    = var.vnet.id

  lifecycle {
    ignore_changes = [ tags ]
  }
}

# AzureOpenAI Private Endpoint
resource "azurerm_private_endpoint" "openai" {
  name                = local.AzOpenAI_pe_name
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  tags                = var.tags

  lifecycle {
    ignore_changes = [tags]
  }

  subnet_id           = var.subnet.id

  private_service_connection {
    name                           = "openai-private-connection"
    private_connection_resource_id = azurerm_cognitive_account.openai.id
    is_manual_connection           = false
    subresource_names              = ["account"]
  }
  private_dns_zone_group {
    name                 = "openai-private-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.openai.id]
  }

  
}

output "openai_endpoint" {
  value = azurerm_cognitive_account.openai.endpoint
}

# Assign Access permission for FunctionApp MSI to Azure OpenAI
data "azurerm_linux_function_app" "func" {
  name                = var.functionApp.name
  resource_group_name = var.resource_group.name
}

resource "azurerm_role_assignment" "func_openai" {
  scope                = azurerm_cognitive_account.openai.id
  principal_id         = data.azurerm_linux_function_app.func.identity[0].principal_id
  role_definition_name = "Contributor"

  lifecycle {
    ignore_changes = [ principal_id ]
  }
}