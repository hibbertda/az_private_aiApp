
locals {
    resource_group_name = "rg-${var.environment.project_name}-${var.environment.location}"
    region              = var.environment.location
    vnet_name           = "vnet-${var.environment.project_name}-${var.environment.location}"
}

resource "azurerm_resource_group" "rg" {
    name     = local.resource_group_name
    location = local.region
    tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
    name                = local.vnet_name
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    tags = var.tags

    lifecycle {
      ignore_changes = [ tags ]
    }

    address_space       = ["10.0.0.0/16"]

}

# SUBNET: Private Endpoint
resource "azurerm_subnet" "subnet" {
    name                 = "pe-${local.vnet_name}"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = ["10.0.1.0/24"]
}
# SUBNET: VNET Integration
resource "azurerm_subnet" "integrationsubnet" {
    name                 = "vnetint-${local.vnet_name}"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = ["10.0.2.0/24"]

    delegation {
      name = "websitesDelegation"
        service_delegation {
            name    = "Microsoft.Web/serverFarms"
            actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
    }
}

# # Module: Azure Key Vault
# module "azure_keyvault" {
#     source          = "./modules/azureKeyVault"
#     environment     = var.environment
#     resource_group  = azurerm_resource_group.rg
#     tags            = var.tags
#     vnet            = azurerm_virtual_network.vnet
#     subnet          = azurerm_subnet.subnet
# }

# Module: Azure Function w/ VNET Integration
module "azure_function" {
    source          = "./modules/azureFunction"
    environment     = var.environment
    resource_group  = azurerm_resource_group.rg
    tags            = var.tags
    vnet            = azurerm_virtual_network.vnet
    subnet          = azurerm_subnet.subnet
    int_subnet      = azurerm_subnet.integrationsubnet
}

# Module: Azure OpenAI
module "azure_openai" {
    source          = "./modules/AzureOpenAI"
    depends_on = [ 
        module.azure_function 
        ]
    
    environment     = var.environment
    resource_group  = azurerm_resource_group.rg
    tags            = var.tags
    vnet            = azurerm_virtual_network.vnet
    subnet          = azurerm_subnet.subnet
    func_MSI        = module.azure_function.funcApp_MSI
    functionApp     = module.azure_function.functionApp
}




