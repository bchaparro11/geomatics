provider "azurerm" {
  features {}
  subscription_id = ""
}

resource "azurerm_resource_group" "example" {
  name     = "r2"
  location = "West US 2"
}

resource "azurerm_virtual_network" "example" {
  name                = "example-vn2"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "example" {
  name                 = "example-sn2"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}
resource "azurerm_private_dns_zone" "example" {
  name                = "example.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  name                  = "exampleVnetZone2.com"
  private_dns_zone_name = azurerm_private_dns_zone.example.name
  virtual_network_id    = azurerm_virtual_network.example.id
  resource_group_name   = azurerm_resource_group.example.name
  depends_on            = [azurerm_subnet.example]
}

resource "azurerm_postgresql_flexible_server" "example" {
  name                          = "example-psqlflexibleserver-3-replica-nl-2"
  resource_group_name           = azurerm_resource_group.example.name
  location                      = azurerm_resource_group.example.location
  version                       = "12"
  delegated_subnet_id           = azurerm_subnet.example.id
  private_dns_zone_id           = azurerm_private_dns_zone.example.id
  public_network_access_enabled = false
  administrator_login           = "psqladmin"
  administrator_password        = "H@Sh1CoR3!"
  zone                          = "1"

  storage_mb   = 32768
  storage_tier = "P4"

  sku_name   = "B_Standard_B1ms"
  depends_on = [azurerm_private_dns_zone_virtual_network_link.example]

}

# First Read Replica
resource "azurerm_postgresql_flexible_server" "replica1" {
  name                   = "pg-replica-1-2"
  resource_group_name    = azurerm_resource_group.example.name
  location               = "Japan East"
  source_server_id       = azurerm_postgresql_flexible_server.example.id
  zone                   = "2"
  administrator_login           = "psqladmin"
  administrator_password        = "H@Sh1CoR3!"
  sku_name   = "B_Standard_B1ms"
  version                       = "12"
}

# Second Read Replica
resource "azurerm_postgresql_flexible_server" "replica2" {
  name                   = "pg-replica-2-3"
  resource_group_name    = azurerm_resource_group.example.name
  location               = "Italy North"
  source_server_id       = azurerm_postgresql_flexible_server.example.id
  zone                   = "3"
  administrator_login           = "psqladmin"
  administrator_password        = "H@Sh1CoR3!"
  sku_name   = "B_Standard_B1ms"
  version                       = "12"
}