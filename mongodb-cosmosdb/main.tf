provider "azurerm" {
    features {}
    subscription_id = ""
  }
  
  resource "azurerm_resource_group" "rg" {
    name     = "mongodb-rg"
    location = "East US"
  }
  
  resource "azurerm_cosmosdb_account" "cosmosdb" {
    name                      = "mongodb-cosmos"
    location                  = azurerm_resource_group.rg.location
    resource_group_name       = azurerm_resource_group.rg.name
    offer_type                = "Standard"
    kind                      = "MongoDB"
    mongo_server_version      = "7.0"
    #enable_automatic_failover = true
    capabilities {
      name = "EnableMongo"
    }
    #capabilities {
    #  name = "MongoDBv7.0"
    #}
    consistency_policy {
      consistency_level = "Session"
    }
    geo_location {
      location          = "Japan East"
      failover_priority = 0
    }
    geo_location {
      location          = "Germany West Central"
      failover_priority = 1
    }

    geo_location {
    location          = "Central US"  # Second Replica
    failover_priority = 2
  }
  }
  
  resource "azurerm_cosmosdb_mongo_database" "mongodb_db" {
    name                = "myMongoDatabase"
    resource_group_name = azurerm_resource_group.rg.name
    account_name        = azurerm_cosmosdb_account.cosmosdb.name
    throughput          = 400
  }
  
  resource "azurerm_cosmosdb_mongo_collection" "mongodb_collection" {
    name                = "myCollection"
    resource_group_name = azurerm_resource_group.rg.name
    account_name        = azurerm_cosmosdb_account.cosmosdb.name
    database_name       = azurerm_cosmosdb_mongo_database.mongodb_db.name
    shard_key          = "_id"
    throughput         = 400
    
    index {
      keys   = ["_id"]
      unique = true
    }
  }