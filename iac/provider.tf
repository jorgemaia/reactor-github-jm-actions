terraform {
  backend "local" {}
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.26.0"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = "true"
  features {}
}
