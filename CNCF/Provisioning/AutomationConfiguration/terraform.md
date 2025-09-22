---
description: Terraform
---

# Terraform

## Introduction
...

## Deploy By Binary
### Install
```bash
# package
apt install terraform

# binary
wget https://releases.hashicorp.com/terraform/1.9.4/terraform_1.9.4_linux_amd64.zip
unzip terraform_1.9.4_linux_amd64.zip && rm -f terraform_1.9.4_linux_amd64.zip
install -m 0755 terraform /usr/bin/terraform
```

### How To Use
```bash
~/terraform $ tree                    
.
├── aws
│   ├── ec2
│   │   ├── server1.tf
│   ├── main.tf
│   ├── terraform.tfvars
│   ├── variables.tf
│   └── vpc
│       └── vpc1.tf
├── docker
│   ├── main.tf
│   ├── outputs.tf
│   └── variables.tf
├── gcp
│   ├── main.tf
│   ├── terraform.tfvars
│   └── variables.tf

# docker test
cat > ./docker/main.tf << "EOF"
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {}

resource "docker_image" "nginx" {
  name         = "nginx"
  keep_locally = false
}

resource "docker_container" "nginx" {
  image = docker_image.nginx.image_id
  //name  = "tutorial"
  name  = var.container_name

  ports {
    internal = 80
    external = 8000
  }
}
EOF

cat > ./docker/variables.tf << "EOF"
variable "container_name" {
  description = "Value of the name for the Docker container"
  type        = string
  default     = "ExampleNginxContainer"
}
EOF

cat > ./docker/outputs.tf << "EOF"
output "container_id" {
  description = "ID of the Docker container"
  value       = docker_container.nginx.id
}

output "image_id" {
  description = "ID of the Docker image"
  value       = docker_image.nginx.id
}
EOF


# pre-action
terraform init
terraform fmt
terraform validate

# apply
terraform plan
terraform apply

# query
terraform show
terraform state list
terraform output
```

## Deploy By Container
### Run On Docker
```bash
# docker container
docker run --rm -it hashicorp/terraform:latest plan
docker run --rm -it -v ~/terraform:/terraform --entrypoint sh hashicorp/terraform:latest

# docker-compose
```



> Reference:
> 1. [Official Website](https://www.terraform.io/)
> 2. [Repository](https://github.com/hashicorp/terraform)
> 3. [Registry](https://registry.terraform.io/)