# GitHub Actions: Helm Chart Publishing to Artifact Registry

This document shows how to configure the GitHub Actions workflow to automatically publish your Helm chart to Google Cloud Artifact Registry.

## What You Get

The GitHub Actions workflow (`.github/workflows/publish-helm-chart.yml`) will:
- ✅ Automatically trigger on pushes to main/master (when `chart/**` files change)
- ✅ Trigger on GitHub releases 
- ✅ Allow manual runs
- ✅ Validate and lint your Helm chart
- ✅ Package and publish to Artifact Registry using OCI format
- ✅ Make charts publicly accessible (no authentication required)

## Prerequisites

1. **Google Cloud Project** with Artifact Registry API enabled
2. **Artifact Registry Repository** for storing Helm charts  
3. **GitHub Repository** with the workflow file

## Quick Setup

### 1. Enable Artifact Registry API
```bash
gcloud services enable artifactregistry.googleapis.com
```

### 2. Create Artifact Registry Repository
```bash
gcloud artifacts repositories create basic-chart \
    --repository-format=docker \
    --location=us-west1 \
    --description="Basic chart helm repository"
```

### 3. Set up Authentication
```bash
# Create service account
gcloud iam service-accounts create helm-publisher \
    --description="Service account for publishing Helm charts to Artifact Registry"

# Grant Artifact Registry Admin permissions  
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:helm-publisher@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/artifactregistry.admin"

# Create and download service account key
gcloud iam service-accounts keys create key.json \
    --iam-account=helm-publisher@YOUR_PROJECT_ID.iam.gserviceaccount.com

# Base64 encode the key for GitHub secret
base64 -i key.json | tr -d '\n'

# Clean up the local key file (important for security)
rm key.json
```

### 4. Configure GitHub Repository

**Add this Repository Secret:**
- `GCP_SA_KEY`: The base64-encoded service account key from step 3

**Add these Repository Variables:**
- `PROJECT_ID`: `your-project-id`  
- `REGISTRY_LOCATION`: `us-west1`
- `REPOSITORY_NAME`: `basic-chart`

## How to Use

### Automatic Publishing
- **Push to main/master**: Uses the version specified in `chart/Chart.yaml`
- **Create GitHub Release**: Uses the version specified in `chart/Chart.yaml`

### Manual Publishing
1. Go to Actions → "Publish Helm Chart to Artifact Registry" 
2. Click "Run workflow"
3. The workflow will use the version from `chart/Chart.yaml`

**Note:** To publish a new version, update the `version` field in `chart/Chart.yaml` and push/create a release.

## After Publishing

Users can install your chart directly (no repo needed):
```bash
# Direct install from Artifact Registry (publicly accessible)
helm install my-app oci://us-west1-docker.pkg.dev/YOUR_PROJECT_ID/basic-chart/base-chart --version 1.0.0

# Or pull the chart locally
helm pull oci://us-west1-docker.pkg.dev/YOUR_PROJECT_ID/basic-chart/base-chart --version 1.0.0
```

## Troubleshooting

**Permission denied**: Check service account has Artifact Registry Admin role
**Chart validation fails**: Run `helm lint chart/` locally first
**Workflow not triggering**: Ensure changes are in `chart/**` directory
**Authentication issues**: Verify GitHub secrets/variables are set correctly
**OCI push fails**: Ensure Artifact Registry API is enabled and repository exists

## Benefits of Artifact Registry

✅ **Native OCI support** - Modern standard for container and Helm chart storage
✅ **Better security** - Integrated IAM with fine-grained permissions  
✅ **Public access** - Charts can be made publicly available without authentication
✅ **No index management** - No need to maintain index.yaml files
✅ **Better performance** - Optimized for package management
✅ **Vulnerability scanning** - Built-in security scanning for charts