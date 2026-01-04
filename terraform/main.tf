terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.6.2"
    }
  }
}

provider "docker" {}

resource "docker_image" "nginx" {
  name = "nginx:alpine"
  build {
    context    = "."
    dockerfile = "Dockerfile"
  }
  keep_locally = false
  triggers = {
    dockerfile_hash = filemd5("${path.module}/Dockerfile")
  }
}

resource "null_resource" "cleanup_container" {
  triggers = {
    image_id = docker_image.nginx.image_id
  }

  provisioner "local-exec" {
    command = "docker stop ${var.container_name} 2>/dev/null || true && docker rm ${var.container_name} 2>/dev/null || true"
  }
}

resource "docker_container" "nginx" {
  image = docker_image.nginx.image_id
  name  = var.container_name
  ports {
    internal = 80
    external = 8080
  }
  depends_on = [null_resource.cleanup_container]
}
