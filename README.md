# Base Chart

Helm chart para deployments Kubernetes com Istio, autoscaling e Infisical.

## Instalacao

```bash
helm install my-app oci://us-west1-docker.pkg.dev/rj-iplanrio-dia/charts/base-chart --version 2.0.0
```

## Exemplos

### Aplicacao basica

```yaml
image:
  repository: my-app
  tag: v1.0.0

replicaCount: 3
```

### API com cache e fila

```yaml
global:
  secretName: my-app-secrets

infisicalSecret:
  enabled: true
  projectSlug: my-project
  envSlug: prod

valkey:
  enabled: true

rabbitmq:
  enabled: true
```

Secrets necessarios no Infisical:
- `REDIS_PASSWORD`
- `RABBITMQ_PASSWORD`
- `RABBITMQ_ERLANG_COOKIE`

Variaveis injetadas automaticamente pelo chart:
| Variavel | Valor | Descricao |
|----------|-------|-----------|
| `REDIS_HOST` | `<release>-valkey` | Hostname do Valkey |
| `REDIS_PORT` | `6379` | Porta do Valkey |
| `RABBITMQ_HOST` | `<release>-rabbitmq` | Hostname do RabbitMQ |
| `RABBITMQ_PORT` | `5672` | Porta AMQP |
| `RABBITMQ_USER` | `<release>` | Usuario (nome do release) |

A aplicacao constroi a connection string usando as variaveis acima + senha do Infisical.

### Autoscaling com KEDA

```yaml
scaledObject:
  enabled: true
  minReplicaCount: 1
  maxReplicaCount: 20
  triggers:
    - type: prometheus
      metadata:
        serverAddress: http://prometheus:9090
        threshold: "100"
        query: sum(rate(istio_requests_total{destination_app="my-app"}[2m]))
```

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

| Wave | Recursos |
|------|----------|
| -1 | InfisicalSecret |
| 0 | ServiceAccount |
| 1 | Service, Deployment |
| 2 | ScaledObject, HPA, PDB, CronJobs |
| 3 | VirtualService, DestinationRule, AuthorizationPolicy, RequestAuthentication |

## Configuracao

Todas as opcoes estao documentadas em `chart/values.yaml`.

### Principais opcoes

| Parametro | Descricao | Padrao |
|-----------|-----------|--------|
| `replicaCount` | Numero de replicas | `1` |
| `image.repository` | Repositorio da imagem | `nginx` |
| `image.tag` | Tag da imagem | `appVersion` |
| `service.port` | Porta do Service | `80` |
| `service.containerPort` | Porta do container | `8080` |
| `istio.enabled` | Habilita Istio | `true` |
| `scaledObject.enabled` | Habilita KEDA | `true` |
| `autoscaling.enabled` | Habilita HPA | `false` |
| `podDisruptionBudget.enabled` | Habilita PDB | `true` |
| `infisicalSecret.enabled` | Habilita Infisical | `false` |
| `valkey.enabled` | Habilita cache Redis | `false` |
| `rabbitmq.enabled` | Habilita fila | `false` |

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

## Publicacao

1. Atualize a versao em `chart/Chart.yaml`
2. Push para main ou crie um release
3. GitHub Actions publica automaticamente
