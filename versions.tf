terraform {
  required_version = ">= 1.3.6, < 1.4.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.46.0, < 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
    }
  }
}