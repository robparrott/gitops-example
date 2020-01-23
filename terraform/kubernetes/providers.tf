provider "kubernetes" {
  config_context_auth_info = "ops"
  config_context_cluster   = "eks-sandbox"
}

resource "kubernetes_namespace" "terraform-example" {
  metadata {
    name = "terraform-namespace"
  }
}