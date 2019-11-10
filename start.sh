#!/bin/bash
set -e


# ----------------------------------------
# Create Minikube cluster
# ----------------------------------------
minikube start \
    --network-plugin=cni \
    --memory=8192 \
    --extra-config=kubeadm.pod-network-cidr=192.168.0.0/16 \
    --cpus=4

kubectl apply -f https://docs.projectcalico.org/v3.10/manifests/calico.yaml

# ----------------------------------------
# Install Helm
# ----------------------------------------
kubectl create sa tiller -n kube-system
kubectl create clusterrolebinding tiller-admin-binding \
    --clusterrole=cluster-admin \
    --serviceaccount=kube-system:tiller

helm init --service-account tiller --wait


# ----------------------------------------
# Install Istio
# ----------------------------------------
ISTIO_VERSION=1.3.4

helm repo add istio.io https://storage.googleapis.com/istio-release/releases/${ISTIO_VERSION}/charts/
helm repo update

helm upgrade istio-init istio.io/istio-init \
    --install \
    --namespace=istio-system \
    --wait

sleep 30 # Waiting for CRDs to become ready
helm upgrade istio istio.io/istio \
    --install \
    --namespace istio-system

kubectl label namespace default istio-injection=enabled --overwrite


# ----------------------------------------
# Create Load Balancer
# ----------------------------------------
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
echo "To assigned IP address to istio-ingressgateway LB"
echo 'run "minikube tunnel" in separate terminal'
echo 'For cleanup run "minikube tunnel --cleanup"'
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
