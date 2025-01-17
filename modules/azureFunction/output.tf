output "funcApp_MSI" {
    value = azurerm_linux_function_app.func.identity[0].principal_id
}

output "functionApp" {
    value = azurerm_linux_function_app.func
}