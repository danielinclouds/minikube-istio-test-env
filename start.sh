#!/bin/bash
set -e


# ----------------------------------------
# Create Minikube cluster
# ----------------------------------------
minikube start \
    --extra-config=kubelet.network-plugin=cni \
    --network-plugin=cni \
    --memory=8192 \
    --cpus=4

kubectl apply -f https://docs.projectcalico.org/v3.2/getting-started/kubernetes/installation/hosted/etcd.yaml
kubectl apply -f https://docs.projectcalico.org/v3.2/getting-started/kubernetes/installation/rbac.yaml

curl https://docs.projectcalico.org/v3.2/getting-started/kubernetes/installation/hosted/calico.yaml -O
gsed -i -e "s/10\.96\.232\.136/$(kubectl get service -o json --namespace=kube-system calico-etcd | jq  -r .spec.clusterIP)/" calico.yaml

kubectl apply -f calico.yaml
rm calico.yaml


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
ISTIO_VERSION=1.2.3

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
