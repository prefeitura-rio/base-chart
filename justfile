# Run lint and template tests by default
default: lint test

# Validate chart structure and best practices
@lint:
    echo "*** Running Helm lint... ***"
    helm lint chart/
    echo "*** Lint completed ***"

# Test all chart templates with various configurations
@test:
    echo "*** Testing all chart templates... ***"
    echo "*** Testing basic templates (deployment, service)... ***"
    helm template test chart/ --dry-run=client > /dev/null
    echo "*** Testing HPA template... ***"
    helm template test chart/ --set autoscaling.enabled=true --dry-run=client > /dev/null
    echo "*** Testing KEDA ScaledObject template... ***"
    helm template test chart/ --set scaledObject.enabled=true --dry-run=client > /dev/null
    echo "*** Testing PodDisruptionBudget template... ***"
    helm template test chart/ --set podDisruptionBudget.enabled=true --dry-run=client > /dev/null
    echo "*** Testing VirtualService template... ***"
    helm template test chart/ --set istio.enabled=true --set istio.virtualService.enabled=true --dry-run=client > /dev/null
    echo "*** Testing DestinationRule template... ***"
    helm template test chart/ --set istio.enabled=true --set istio.destinationRule.enabled=true --dry-run=client > /dev/null
    echo "*** Testing RequestAuthentication template... ***"
    helm template test chart/ --set istio.enabled=true --set istio.requestAuthentication.enabled=true --dry-run=client > /dev/null
    echo "*** Testing AuthorizationPolicy template... ***"
    helm template test chart/ --set istio.enabled=true --set istio.authorizationPolicy.enabled=true --dry-run=client > /dev/null
    echo "*** Testing NOTES.txt with different service types... ***"
    helm template test chart/ --set service.type=NodePort --dry-run=client > /dev/null
    helm template test chart/ --set service.type=LoadBalancer --dry-run=client > /dev/null
    helm template test chart/ --set service.type=ClusterIP --dry-run=client > /dev/null
    echo "*** Testing all features enabled... ***"
    helm template test chart/ \
        --set istio.enabled=true \
        --set istio.virtualService.enabled=true \
        --set istio.destinationRule.enabled=true \
        --set istio.requestAuthentication.enabled=true \
        --set istio.authorizationPolicy.enabled=true \
        --set autoscaling.enabled=true \
        --set scaledObject.enabled=true \
        --set podDisruptionBudget.enabled=true \
        --dry-run=client > /dev/null
    echo "*** All 10 templates tested successfully! ***"

# Generate all rendered templates to debug directory
@debug:
    echo "*** Generating all templates for debugging... ***"
    mkdir -p debug
    helm template debug-release chart/ --output-dir debug/
    echo "*** Templates saved to debug/ ***"

# Display all rendered resources to stdout
@show:
    echo "*** Showing all resources: ***"
    helm template show-release chart/ --set image.repository=nginx --set image.tag=alpine

# Remove debug files and cleanup artifacts
@clean:
    echo "*** Cleaning up... ***"
    rm -rf debug/
    echo "*** Cleanup completed ***"

# Show chart metadata and default values
@info:
    echo "*** Chart Information: ***"
    helm show chart chart/
    echo ""
    echo "*** Chart Values: ***"
    helm show values chart/

# Create a .tgz package of the chart
@package:
    echo "*** Packaging chart... ***"
    helm package chart/
    echo "*** Chart packaged successfully ***"
