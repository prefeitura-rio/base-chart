# Base Chart

Um Helm chart pronto para produção para deployments Kubernetes com integração completa do Istio service mesh, autoscaling e recursos de alta disponibilidade.

## Funcionalidades

- **Deploy sem Configuração**: Funciona imediatamente com configurações padrão sensatas
- **Pronto para Produção**: Inclui PodDisruptionBudget, limites de recursos e health probes
- **Istio Service Mesh**: Integração completa com VirtualService, DestinationRule e políticas de segurança
- **Auto-Scaling**: Suporte tanto HPA tradicional quanto KEDA ScaledObject
- **Alta Disponibilidade**: Disruption budgets integrados e connection pooling
- **Segurança**: Integração com Infisical, autenticação JWT e políticas de autorização
- **Atualizações Automáticas**: Suporte opcional para Argo Image Updater

## Início Rápido

### Instalação Direta (Público)

```bash
# Instalação direta do Artifact Registry (publicamente acessível)
helm install my-app oci://us-west1-docker.pkg.dev/rj-iplanrio-dia/charts/base-chart --version 0.1.0

# Deploy com configurações customizadas
helm install my-app oci://us-west1-docker.pkg.dev/rj-iplanrio-dia/charts/base-chart \
  --set image.repository=my-app \
  --set image.tag=v1.0.0 \
  --set replicaCount=3

# Deploy sem Istio
helm install my-app oci://us-west1-docker.pkg.dev/rj-iplanrio-dia/charts/base-chart \
  --set istio.enabled=false
```

### Desenvolvimento Local

```bash
# Deploy básico (Istio habilitado por padrão)
helm install my-app ./chart

# Deploy com imagem customizada
helm install my-app ./chart \
  --set image.repository=my-app \
  --set image.tag=v1.0.0 \
  --set replicaCount=3
```

## Padrões de Uso Comuns

### 1. Aplicação Web Simples

```bash
helm install web-app oci://us-west1-docker.pkg.dev/rj-iplanrio-dia/charts/base-chart \
  --set image.repository=nginx \
  --set service.port=80
```

### 2. API com Autenticação JWT

```yaml
# values.yaml
image:
  repository: minha-api
  tag: v1.2.3

istio:
  enabled: true
  requestAuthentication:
    enabled: true
    jwtRules:
      - issuer: "https://auth.empresa.com"
        jwksUri: "https://auth.empresa.com/.well-known/jwks.json"
```

### 3. Microsserviço com Autoscaling

```yaml
# values.yaml
istio:
  virtualService:
    pathBasedRouting:
      enabled: true
      servicePath: "user-service"

scaledObject:
  enabled: true
  maxReplicaCount: 20
  triggers:
    - type: prometheus
      metadata:
        serverAddress: http://prometheus.istio-system.svc.cluster.local:9090
        threshold: "50"
        query: sum(rate(istio_requests_total{destination_app="user-service"}[1m]))
```

### 4. Atualização Automática com Argo Image Updater

```yaml
# values.yaml
argoImageUpdater:
  enabled: true
  namespace: argocd
  applicationRef:
    namePattern: "minha-api-app"
  images:
    - alias: "api"
      imageName: "ghcr.io/empresa/minha-api"
      commonUpdateSettings:
        updateStrategy: "digest"
    - alias: "frontend"
      imageName: "ghcr.io/empresa/meu-frontend"
      commonUpdateSettings:
        updateStrategy: "semver"
        semverConstraint: "~1.2.0"
```

## Configuração para Desenvolvedores

Para contribuir e publicar novas versões:

### Pré-requisitos

- Google Cloud Project com Artifact Registry API habilitado
- Service account com `roles/artifactregistry.admin`

### Configuração do Repositório GitHub

- **Secrets:** `GCP_SA_KEY` (chave da service account codificada em base64)
- **Variáveis:** `PROJECT_ID` (ID do seu projeto GCP)

### Publicação

1. Atualize a versão em `chart/Chart.yaml`
2. Faça push para main ou crie um GitHub release
3. GitHub Actions publica automaticamente no Artifact Registry

## Migração e Troubleshooting

### Habilitando Istio em Deploy Existente

1. Certifique-se de que o Istio está instalado no cluster
2. Atualize: `helm upgrade my-app oci://us-west1-docker.pkg.dev/rj-iplanrio-dia/charts/base-chart --set istio.enabled=true`

### Problemas Comuns

- **Sidecar não injetado**: Namespace precisa do label `istio-injection=enabled`
- **KEDA não funciona**: Verifique se KEDA está instalado no cluster
- **Tráfego bloqueado**: AuthorizationPolicy muito restritivo - comece com `rules: [{}]`

### Comandos Úteis

```bash
# Verificar recursos Istio
kubectl get virtualservices,destinationrules -A

# Verificar autoscaling
kubectl get scaledobjects,hpa -A

# Status do service mesh
istioctl proxy-status
```

## Configuração

Consulte `chart/values.yaml` para todas as opções de configuração com comentários detalhados em português.

## Roadmap

### Funcionalidades Planejadas

- **🚀 Argo Rollouts**: Integração com Argo Rollouts para deployments avançados (blue/green, canary, análise automatizada)
- **📊 Observabilidade**: Templates para Grafana dashboards e alertas Prometheus
- **💾 Persistência**: Suporte para volumes persistentes e StatefulSets

## Requisitos

- Kubernetes 1.19+
- Helm 3.2.0+
- Istio 1.14+ (opcional)
- KEDA 2.0+ (opcional)
- Argo Image Updater 0.12+ (opcional)
