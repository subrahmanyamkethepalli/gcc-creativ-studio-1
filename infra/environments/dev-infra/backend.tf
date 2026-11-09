terraform {
  backend "gcs" {
    bucket = "sbd-ai-poc-h-cstudio-dev-infra-tfstate"
    prefix = "infra/dev-infra/state"
  }
}
