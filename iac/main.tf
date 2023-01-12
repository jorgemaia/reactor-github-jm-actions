variable "env" {
  default = "d34"
  type    = string
} 

variable "rgname" {
  default = "rg-reactor-d34"
  type    = string
} 

variable "regiao" {
  default = "eastus2"
  type    = string
} 

 resource "azurerm_resource_group" "rg" {
   name     = var.rgname
   location = var.regiao
 }

# Cosmos DB 
resource "azurerm_cosmosdb_account" "cosmosdb" {
  name                = "cosmos-reactordemojm-${var.env}"
  location            = var.regiao
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"

capabilities {
  name = "EnableServerless"
}

consistency_policy {
 consistency_level = "BoundedStaleness" 
}

  geo_location {
    location          = var.regiao
    failover_priority = 0
  }
}



resource "azurerm_mssql_server" "sqld" {
  name                         = "sql-reactordemojm-${var.env}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.regiao
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "Q!W@E#RXSE%$234GSFDDFG2aeDFG"
}


resource "azurerm_mssql_database" "sqldb" {
  name           = "sqldb-reactordemojm-${var.env}"
  server_id      = azurerm_mssql_server.sqld.id
  collation      = "SQL_Latin1_General_CP1_CI_AI"
  license_type   = "LicenseIncluded"
  max_size_gb    = 250
  sku_name       = "S0"
 
}


locals{
  sqlconn =  "Server=tcp:${azurerm_mssql_server.sqld.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.sqldb.name};Persist Security Info=False;User ID=${azurerm_mssql_server.sqld.administrator_login};Password=${azurerm_mssql_server.sqld.administrator_login_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  cosmosconn = "${azurerm_cosmosdb_account.cosmosdb.connection_strings[0]}"
}

output "sqlconn" {
  value = local.sqlconn
  sensitive = true
}

output "cosmosconn" {
  value = local.cosmosconn
  sensitive = true
}


### Application Insights

resource "azurerm_application_insights" "appinsights" {
  name                = "appi-func-reactordemojm-${var.env}"
  location            = var.regiao
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}

#App Service Plan
resource "azurerm_service_plan" "plan" {
  name                = "plan-reactordemojm-${var.env}"
  location            = var.regiao
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "S1"
}




# Aplicação 
resource "azurerm_linux_web_app" "app" {
  name                = "app-reactordemojm-${var.env}"
  location            = var.regiao
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.plan.id
  https_only          = true
  #tags = local.common_tags
  
  site_config {
    always_on                = true
 #   cors {
 #     allowed_origins = [azurerm_linux_web_app.XXXXX]
 #   }
  
  application_stack {
    dotnet_version = "6.0"
  }

  }

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY"      = azurerm_application_insights.appinsights.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.appinsights.connection_string
    "TZ" = "America/sao_paulo"
    "CosmosDBConnection" = local.cosmosconn
    "SQLConnection" = local.sqlconn
  }

 
}

