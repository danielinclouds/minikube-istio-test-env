#!/bin/bash

# Prometheus
helm upgrade prometheus stable/prometheus \
    --install \
    --namespace=monitoring \
    --set nodeExporter.enabled=false \
    --set alertmanager.enabled=false \
    --set pushgateway.enabled=false \
    --values ./prometheus-values.yaml


# Grafana
kubectl -n monitoring create secret generic grafana-admin \
    --from-literal="admin-user=admin" \
    --from-literal="admin-password=admin"

helm upgrade grafana stable/grafana \
    --install \
    --namespace=monitoring \
    --values ./grafana-values.yaml