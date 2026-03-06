# Deployment Repository

This repository contains a Terraform-based deployment system for Docker Swarm services. Service configurations are defined in YAML files (`service.yaml`) and deployed via Terraform modules.

## Overview

The system uses:
- **Terraform** to manage Docker Swarm services declaratively
- **`service.yaml`** files to define application stacks in a simplified YAML format
- **Environment overrides** (`dev.yaml`, `prod.yaml`) for environment-specific configuration
- **PostgreSQL backend** for storing Terraform state
- **GitHub Actions** for automated CI/CD deployments

## Prerequisites

- Terraform >= 1.0
- Docker Swarm initialized on VPS
- SSH access to VPS with Docker permissions
- `jq` installed on VPS (required for secret lookup script)
- GitHub repository with Actions enabled (for automated deployments)

## Directory Structure

```
├── stacks/                      # Application stack definitions
│   └── <stack-name>/
│       ├── service.yaml         # Base service configuration
│       └── overrides/
│           ├── dev.yaml         # Dev environment overrides
│           └── prod.yaml        # Prod environment overrides
├── infra/
│   ├── modules/                 # Reusable Terraform modules
│   │   └── swarm-stack/         # Core module for Docker Swarm services
│   ├── environments/            # Environment-specific configurations
│   │   ├── dev/
│   │   └── prod/
│   ├── bootstrap/               # State backend setup (PostgreSQL)
│   └── scripts/                 # Helper scripts (secret lookup)
└── .github/workflows/           # CI/CD pipeline definitions
```

## Initial VPS Setup

Before deploying any stacks, initialize Docker Swarm on your VPS:

```bash
# Initialize Docker Swarm
docker swarm init

# Create the external overlay network used by all stacks
docker network create -d overlay main
```

## Secret Management

Docker Swarm secrets must be created manually before deploying stacks that reference them.

### Creating Secrets

```bash
# Create a secret from a value
echo "my-secret-value" | docker secret create SECRET_NAME -

# Create a secret from a file
docker secret create SECRET_NAME /path/to/secret/file

# List existing secrets
docker secret ls

# Inspect a secret (shows metadata only, not the value)
docker secret inspect SECRET_NAME
```

### Required Secrets by Stack

**SITA Stack:**
- `DB_USERNAME` - Database username
- `DB_PASSWORD` - Database password
- `SITA_BOT_ALERTING_URL` - Alerting webhook URL
- `DB_CONNECTION_STRING_DEV` - Dev database connection string
- `DB_CONNECTION_STRING_PROD` - Prod database connection string
- `SITA_BOT_ALERTING_CHANNEL_ID_DEV` - Dev alerting channel ID
- `SITA_BOT_ALERTING_CHANNEL_ID_PROD` - Prod alerting channel ID

## Bootstrap (PostgreSQL State Backend)

The Terraform state is stored in a PostgreSQL database running on the VPS. Set this up first:

```bash
cd infra/bootstrap

terraform init

terraform apply \
  -var='docker_host=ssh://deploy@your-vps-ip' \
  -var='postgres_password=STRONG_PASSWORD'
```

This creates a PostgreSQL container (`terraform-state-db`) that stores Terraform state for all environments.

**Important:** The bootstrap uses local state. Keep the `terraform.tfstate` file in `infra/bootstrap/` safe - losing it means losing track of the state backend container.

## Local Development / Manual Deployment

### Deploy Dev Environment

```bash
cd infra/environments/dev

# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Set the backend connection string
export PG_CONN_STR="postgres://terraform:STRONG_PASSWORD@your-vps-ip/terraform_state?sslmode=disable"

# Initialize and apply
terraform init
terraform apply
```

### Deploy Prod Environment

```bash
cd infra/environments/prod

# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Set the backend connection string
export PG_CONN_STR="postgres://terraform:STRONG_PASSWORD@your-vps-ip/terraform_state?sslmode=disable"

# Initialize and apply
terraform init
terraform apply
```

### Environment Variables

| Variable | Description |
|----------|-------------|
| `PG_CONN_STR` | PostgreSQL connection string for Terraform state backend |
| `TF_VAR_docker_host` | Docker host URI (alternative to terraform.tfvars) |

## GitHub Actions Setup

The repository includes GitHub Actions workflows for automated deployments.

### Configure GitHub Environments

1. Go to **Settings > Environments** in your GitHub repository
2. Create two environments: `dev` and `prod`
3. For `prod`, configure protection rules:
   - Enable **Required reviewers** and add approvers
   - Optionally restrict to specific branches (`main`)

### Required Secrets

Add these secrets to each environment (**Settings > Environments > [env] > Environment secrets**):

| Secret | Description |
|--------|-------------|
| `DOCKER_HOST` | Docker host URI, e.g., `ssh://deploy@your-vps-ip:22` |
| `TF_BACKEND_CONN_STR` | PostgreSQL connection string for Terraform state |

### Workflow Behavior

- **On push to `main`**: Automatically applies changes to affected environments
- **Dev deploys first**, then **prod** (if dev succeeds or is skipped)
- Changes are detected automatically based on modified files
- Prod deployments require approval if protection rules are configured

## Adding a New Stack

### 1. Create the Stack Directory

```bash
mkdir -p stacks/<stack-name>/overrides
```

### 2. Create `service.yaml`

Define the base service configuration:

```yaml
version: "1"

stack:
  name: my-app
  description: "My Application Stack"

services:
  api:
    image:
      repository: registry.example.com/my-app
      tag: "latest"
    replicas: 1
    resources:
      limits:
        cpu: "0.50"
        memory: "500M"
      reservations:
        cpu: "0.25"
        memory: "250M"
    networks:
      - main

networks:
  main:
    external: true
```

### 3. Create Override Files

**`overrides/dev.yaml`:**
```yaml
services:
  api:
    image:
      tag: "dev-latest"
```

**`overrides/prod.yaml`:**
```yaml
services:
  api:
    image:
      tag: "1.0.0"
```

### 4. Add Module Instantiation

Add the stack to `infra/environments/dev/stacks.tf` and `infra/environments/prod/stacks.tf`:

```hcl
# -----------------------------------------------------------------------------
# My App Stack
# -----------------------------------------------------------------------------

locals {
  myapp_base     = yamldecode(file("${path.root}/../../../stacks/my-app/service.yaml"))
  myapp_override = yamldecode(file("${path.root}/../../../stacks/my-app/overrides/dev.yaml"))
  myapp_config = {
    services = {
      for k, v in local.myapp_base.services :
      k => merge(v, lookup(local.myapp_override.services, k, {}), {
        image   = merge(v.image, try(local.myapp_override.services[k].image, {}))
        secrets = try(local.myapp_override.services[k].secrets, try(v.secrets, []))
      })
    }
    networks = lookup(local.myapp_base, "networks", {})
    volumes  = lookup(local.myapp_base, "volumes", {})
  }

  myapp_secret_names = distinct(flatten([
    for svc_name, svc in local.myapp_config.services : [
      for secret in try(svc.secrets, []) :
      coalesce(try(secret.source, null), try(secret.name, null))
    ]
  ]))
}

data "external" "myapp_secrets" {
  for_each = toset(local.myapp_secret_names)

  program = ["bash", "${path.root}/../../scripts/get-secret-id.sh"]

  query = {
    name = each.value
  }
}

module "myapp" {
  source = "../../modules/swarm-stack"

  stack_name = "my-app-dev"  # Use "my-app-prod" for prod
  services   = local.myapp_config.services
  networks   = local.myapp_config.networks
  volumes    = local.myapp_config.volumes
  secret_ids = {
    for name in local.myapp_secret_names :
    name => data.external.myapp_secrets[name].result.id
  }
}
```

## service.yaml Schema Reference

### Top-Level Structure

```yaml
version: "1"                    # Schema version (required)

stack:
  name: string                  # Stack identifier (required)
  description: string           # Human-readable description

services:                       # Map of service definitions (required)
  <service-name>:
    ...

networks:                       # Map of network definitions
  <network-name>:
    external: bool              # Whether network exists externally (default: false)
    driver: string              # Network driver (default: "overlay")

volumes:                        # Map of volume definitions
  <volume-name>:
    driver: string              # Volume driver (default: "local")
```

### Service Definition

```yaml
services:
  <service-name>:
    image:                      # Container image (required)
      repository: string        # Image repository (required)
      tag: string               # Image tag (required)

    replicas: number            # Number of replicas (default: 1)

    resources:                  # Resource constraints
      limits:
        cpu: string             # CPU limit, e.g., "0.50"
        memory: string          # Memory limit, e.g., "500M" or "1G"
      reservations:
        cpu: string             # CPU reservation
        memory: string          # Memory reservation

    update:                     # Rolling update configuration
      parallelism: number       # Tasks to update in parallel (default: 1)
      order: string             # "start-first" or "stop-first" (default: "stop-first")
      delay: string             # Delay between updates (default: "10s")

    restart:                    # Restart policy
      condition: string         # "on-failure", "any", or "none" (default: "on-failure")
      delay: string             # Delay before restart (default: "5s")

    environment:                # Environment variables
      - name: string            # Variable name
        value: string           # Variable value

    secrets:                    # Docker Swarm secrets
      - name: string            # Secret name (simple form)
      # OR
      - source: string          # Secret name in Docker Swarm
        target: string          # Filename in /run/secrets/
        mode: string            # File permissions (default: "0444")

    networks:                   # Networks to attach
      - string                  # Network name

    healthcheck:                # Container health check
      test:                     # Health check command
        - string                # e.g., ["CMD", "curl", "-f", "http://localhost/health"]
      interval: string          # Check interval (default: "30s")
      timeout: string           # Check timeout (default: "10s")
      retries: number           # Retries before unhealthy (default: 3)
```

### Override Files

Override files (`overrides/dev.yaml`, `overrides/prod.yaml`) use the same structure but only include fields to override:

```yaml
services:
  api:
    image:
      tag: "1.2.3"              # Override just the tag
    secrets:                    # Override secrets completely
      - name: DB_PASSWORD
      - source: DB_URL_PROD
        target: DB_URL
```

**Note:** The `secrets` array is replaced entirely (not merged) when specified in an override file.

### Complete Example

**`stacks/sita/service.yaml`:**
```yaml
version: "1"

stack:
  name: sita
  description: "SITA Application Stack"

services:
  frontend:
    image:
      repository: registry.simpletactics.de/sitafrontend
      tag: "latest"
    replicas: 1
    resources:
      limits:
        cpu: "0.50"
        memory: "500M"
      reservations:
        cpu: "0.25"
        memory: "250M"
    update:
      parallelism: 1
      order: start-first
    restart:
      condition: on-failure
    networks:
      - main

  backend:
    image:
      repository: registry.simpletactics.de/sitabackend
      tag: "latest"
    replicas: 1
    resources:
      limits:
        cpu: "0.50"
        memory: "500M"
      reservations:
        cpu: "0.25"
        memory: "250M"
    environment:
      - name: TZ
        value: "Europe/Berlin"
    secrets:
      - name: DB_USERNAME
      - name: DB_PASSWORD
    networks:
      - main

networks:
  main:
    external: true
```

**`stacks/sita/overrides/prod.yaml`:**
```yaml
services:
  frontend:
    image:
      tag: "2.5.2"

  backend:
    image:
      tag: "2.5.1"
    secrets:
      - name: DB_USERNAME
      - name: DB_PASSWORD
      - name: SITA_BOT_ALERTING_URL
      - source: DB_CONNECTION_STRING_PROD
        target: DB_CONNECTION_STRING
        mode: "0400"
      - source: SITA_BOT_ALERTING_CHANNEL_ID_PROD
        target: SITA_BOT_ALERTING_CHANNEL_ID
        mode: "0400"
```
