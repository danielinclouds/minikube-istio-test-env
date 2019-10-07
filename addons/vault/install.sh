#!/bin/bash

helm repo add banzaicloud-stable https://kubernetes-charts.banzaicloud.com
helm repo update

# Disable Istio on default namespace
kubectl label ns default istio-injection-

# Install mysql backend for vault
helm upgrade mysql stable/mysql \
    --install \
    --set mysqlUser=vault \
    --set mysqlDatabase=vault \
    --wait

# Install the Vault with MySQL backend
sleep 15
helm upgrade vault banzaicloud-stable/vault \
    --install \
    --set vault.config.storage.mysql.address=mysql:3306 \
    --set vault.config.storage.mysql.username=vault \
    --set vault.config.storage.mysql.password="[[.Env.MYSQL_PASSWORD]]" \
    --set "vault.envSecrets[0].secretName=mysql" \
    --set "vault.envSecrets[0].secretKey=mysql-password" \
    --set "vault.envSecrets[0].envName=MYSQL_PASSWORD" \
    --wait
