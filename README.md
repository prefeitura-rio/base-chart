# Base Chart

Helm chart for Kubernetes deployments with smart defaults, Istio service mesh, KEDA autoscaling, and Infisical secrets management.

## Features

- **Smart Defaults**: Minimal configuration needed, auto-derives common values
- **Unified Autoscaling**: Merged HPA/KEDA configuration
- **ConfigMap Support**: Mount as environment variables or files
- **Init Containers**: With automatic secret/volume inheritance
- **Istio Integration**: Auto-derived VirtualService destinations
- **Production Security**: Enabled by default (runAsNonRoot, seccomp, drop ALL)
- **ArgoCD Ready**: Sync waves for proper resource ordering

## Installation

```bash
helm install my-app oci://us-west1-docker.pkg.dev/rj-iplanrio-dia/charts/base-chart --version 2.2.1
```

## Exemplos

### Aplicacao basica

```yaml
image:
  repository: my-app
  tag: v1.0.0

replicaCount: 3
```

### API with cache and queue

```yaml
# Centralized secret configuration
infisicalSecret:
  enabled: true
  secretName: "my-app-secrets"  # ✅ Define once
  projectSlug: my-project
  envSlug: prod

# Valkey (Redis) cache
valkey:
  enabled: true
  auth:
    enabled: true
    existingSecret: "my-app-secrets"  # ⚠️ Must match infisicalSecret.secretName
    existingSecretPasswordKey: "REDIS_PASSWORD"

# RabbitMQ queue
rabbitmq:
  enabled: true
  auth:
    enabled: true
    existingSecret: "my-app-secrets"  # ⚠️ Must match infisicalSecret.secretName
    existingPasswordKey: "RABBITMQ_PASSWORD"
    existingErlangCookieKey: "RABBITMQ_ERLANG_COOKIE"
```

**Why the repetition?** Helm subcharts cannot automatically inherit parent values. You must explicitly set `existingSecret` to match `infisicalSecret.secretName`. This is a Helm limitation, not a chart bug.

**Required secrets in Infisical:**
- `REDIS_PASSWORD`
- `RABBITMQ_PASSWORD`
- `RABBITMQ_ERLANG_COOKIE`

**Auto-injected environment variables:**
| Variable | Value | Description |
|----------|-------|-------------|
| `REDIS_HOST` | `<release>-valkey` | Valkey hostname |
| `REDIS_PORT` | `6379` | Valkey port |
| `RABBITMQ_HOST` | `<release>-rabbitmq` | RabbitMQ hostname |
| `RABBITMQ_PORT` | `5672` | AMQP port |
| `RABBITMQ_USER` | `<release>` | Username (release name) |

Your application builds connection strings using these variables + passwords from Infisical.

### Autoscaling with KEDA (v2.2+)

```yaml
# Unified autoscaling configuration
autoscaling:
  minReplicas: 1
  maxReplicas: 20
  keda:
    enabled: true  # Default when autoscaling configured
    triggers:
      - type: prometheus
        metadata:
          # Smart defaults - only specify what's different
          threshold: "100"
          query: sum(rate(istio_requests_total{destination_app="my-app"}[2m]))
          # serverAddress auto-defaults to prometheus-server.istio-system
```

**Smart defaults for Prometheus:**
- `serverAddress`: `http://prometheus-server.istio-system.svc.cluster.local:9090`
- `metricName`: `istio_requests_total`
- `threshold`: `"100"`

### VirtualService com headers e CORS

```yaml
istio:
  virtualService:
    timeout: "30s"
    retries:
      attempts: 3
      perTryTimeout: "10s"
    headers:
      response:
        set:
          cache-control: "public, max-age=86400"
    corsPolicy:
      allowOrigins:
        - exact: "https://example.com"
      allowMethods:
        - GET
        - POST
      allowCredentials: true
```

### Autenticacao JWT

```yaml
istio:
  requestAuthentication:
    enabled: true
    jwtRules:
      - issuer: "https://auth.example.com"
        jwksUri: "https://auth.example.com/.well-known/jwks.json"
```

### Autorizacao com Cerbos/OPA

```yaml
istio:
  authorizationPolicy:
    enabled: true
    action: CUSTOM
    provider:
      name: cerbos-authz
```

### CronJobs

```yaml
cronjobs:
  cleanup:
    enabled: true
    schedule: "0 2 * * *"
    command:
      - /bin/sh
      - -c
      - "python manage.py cleanup"

  backup:
    enabled: true
    schedule: "0 5 * * *"
    command:
      - /bin/sh
      - -c
      - "pg_dump $DATABASE_URL > /backup/db.sql"
    resources:
      limits:
        memory: 1Gi
```

### ServiceAccount (Workload Identity)

```yaml
serviceAccount:
  create: true
  annotations:
    iam.gke.io/gcp-service-account: my-sa@project.iam.gserviceaccount.com
```

## Sync Waves

Recursos sao aplicados em ordem pelo ArgoCD:

| Wave | Recursos                                                                    |
| ---- | --------------------------------------------------------------------------- |
| -1   | InfisicalSecret                                                             |
| 0    | ServiceAccount                                                              |
| 1    | Service, Deployment                                                         |
| 2    | ScaledObject, HPA, PDB, CronJobs                                            |
| 3    | VirtualService, DestinationRule, AuthorizationPolicy, RequestAuthentication |

## Configuracao

Todas as opcoes estao documentadas em `chart/values.yaml`.

### Principais opcoes

| Parametro                     | Descricao             | Padrao       |
| ----------------------------- | --------------------- | ------------ |
| `replicaCount`                | Numero de replicas    | `1`          |
| `image.repository`            | Repositorio da imagem | `nginx`      |
| `image.tag`                   | Tag da imagem         | `appVersion` |
| `service.port`                | Porta do Service      | `80`         |
| `service.containerPort`       | Porta do container    | `8080`       |
| `istio.enabled`               | Habilita Istio        | `true`       |
| `scaledObject.enabled`        | Habilita KEDA         | `true`       |
| `autoscaling.enabled`         | Habilita HPA          | `false`      |
| `podDisruptionBudget.enabled` | Habilita PDB          | `true`       |
| `infisicalSecret.enabled`     | Habilita Infisical    | `false`      |
| `valkey.enabled`              | Habilita cache Redis  | `false`      |
| `rabbitmq.enabled`            | Habilita fila         | `false`      |

## Requisitos

- Kubernetes 1.19+
- Helm 3.2.0+
- Istio 1.14+ (opcional)
- KEDA 2.0+ (opcional)
- Infisical Operator (opcional)

## Desenvolvimento

```bash
# Instalar dependencias
helm dependency update chart/

# Rodar testes
helm unittest chart/

# Instalar localmente
helm install my-app ./chart
```

## v2.2+ New Features

### ConfigMap Support
```yaml
configMap:
  enabled: true
  data:
    LOG_LEVEL: "info"
    API_TIMEOUT: "30"
  # Mount as env vars (default) or as files via mountPath
```

### Init Containers
```yaml
initContainers:
  - name: run-migrations
    command: ["python", "manage.py", "migrate"]
    # Automatically inherits image, secrets, volumes from main deployment
```

### Simplified Health Checks
```yaml
healthCheck:
  path: /health  # Applied to both liveness and readiness probes
```

### ArgoCD Image Updater (Smart Defaults)
```yaml
argoImageUpdater:
  enabled: true
  updateStrategy: "digest"
  # Auto-derives: namespace, applicationRef, images, registrySecret from imagePullSecrets
```

## Secret Management Pattern

**Single Source of Truth: `infisicalSecret.secretName`**

1. Define secret name once in `infisicalSecret.secretName`
2. Reference it explicitly in subcharts (valkey, rabbitmq)
3. Deployment automatically uses it in `envFrom`

```yaml
infisicalSecret:
  secretName: "my-app-secrets"  # ← Define ONCE

valkey:
  auth:
    existingSecret: "my-app-secrets"  # ← Repeat (Helm limitation)

rabbitmq:
  auth:
    existingSecret: "my-app-secrets"  # ← Repeat (Helm limitation)
```

This repetition is unavoidable due to how Helm subcharts work, but keeps configuration explicit and debuggable.

## Publication

1. Update version in `chart/Chart.yaml`
2. Push to main or create a release
3. GitHub Actions publishes automatically
