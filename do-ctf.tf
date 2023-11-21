terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "2.25.2"
    }
  }
}

variable "do_token" {}
variable "access_id" {}
variable "secret_key" {}
# Provider Config
provider "digitalocean" {
  token = var.do_token
  spaces_access_id = var.access_id
  spaces_secret_key = var.secret_key
}
provider "kubernetes" {
  host = data.digitalocean_kubernetes_cluster.tuctf-dev.endpoint
  token = data.digitalocean_kubernetes_cluster.tuctf-dev.kube_config[0].token
  cluster_ca_certificate = base64decode(
    data.digitalocean_kubernetes_cluster.tuctf-dev.kube_config[0].cluster_ca_certificate
  )
}

resource "digitalocean_project" "tuctf-dev" {
  name        = "tuctf-dev"
  description = "Development Config for TUCTF"
  purpose     = "Class Project"
  environment = "Development"
  resources = [
    digitalocean_container_registry.tuctf-registry.urn, 
    digitalocean_kubernetes_cluster.urn,
    digitalocean_loadbalancer.urn ]
}

# K8s Cluster 
resource "digitalocean_kubernetes_cluster" "tuctf-dev" {
  name = "tuctf-dev"
  region = "nyc3"
  version = data.digitalocean_kubernetes_versions.tuctf-dev.latest_version
  node_pool {
    name = "worker-pool"
    size = "s-2vcpu-2gb"
    auto_scale = true
    min_nodes = 1
    max_nodes = 5
  }
}

# Registry Config & Tieing into K8s
resource "digitalocean_container_registry" "tuctf-registry" {
  name                   = "tuctf-registry"
  subscription_tier_slug = "professional"
  region = "nyc3"
}
resource "digitalocean_container_registry_docker_credentials" "tuctf-registry" {
  registry_name = "tuctf-registry"
}
resource "kubernetes_secret" "tuctf-dev" {
  metadata {
    name = "docker-cfg"
  }

  data = {
    ".dockerconfigjson" = digitalocean_container_registry_docker_credentials.tuctf-dev.docker_credentials
  }

  type = "kubernetes.io/dockerconfigjson"
}

# Load Balancer for K8s Cluster
resource "digitalocean_loadbalancer" "public" {
  name   = "loadbalancer-1"
  region = "nyc3"

  forwarding_rule {
    entry_port     = 443
    entry_protocol = "https"

    target_port     = 80
    target_protocol = "http"
  }

  healthcheck {
    port     = 22
    protocol = "tcp"
  }

  droplet_ids = [digitalocean_kubernetes_cluster.tuctf-dev.id]
}

# Digital Ocean space for CTFd 
resource "digitalocean_spaces_bucket" "ctfd" {
  name   = "ctfd"
  region = "nyc3"
}

resource "digitalocean_kubernetes_cluster" "tuctf-dev" {
  name = "tuctf-dev"
  region = "nyc3"
  version = data.digitalocean_kubernetes_versions.tuctf-dev.latest_version
  node_pool {
    name = "worker-pool"
    size = "s-2vcpu-2gb"
    auto_scale = true
    min_nodes = 1
    max_nodes = 5
  }
}

resource "time_sleep" "wait_for_kubernetes" {

    depends_on = [
        digitalocean_kubernetes_cluster.tuctf-dev
    ]

    create_duration = "20s"
}

data "digitalocean_kubernetes_cluster" "tuctf-dev" {
  name = "tuctf-dev"
}
data "digitalocean_kubernetes_versions" "tuctf-dev" {}
data "digitalocean_loadbalancer" "public" {
  id = digitalocean_loadbalancer.public.id
ijtvltpzlshvxzemtmjrapqlsnonwpkmxuncaihyzdztzngftwkufrpecwxzrnccyglwqbhyxjurrqtofwgglalbnvlkygpktgnr