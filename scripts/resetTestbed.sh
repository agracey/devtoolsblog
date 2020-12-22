#!/usr/bin/env bash
set -Eeuo pipefail

ssh root@192.168.1.12 /usr/local/bin/k3s-uninstall.sh
rm kubeconfig

# Assumes that ssh-copy-id has been run for remote root user
k3sup install --ip 192.168.1.12

export KUBECONFIG=$PWD/kubeconfig
echo "KUBECONFIG at " + $KUBECONFIG

helm repo update

kubectl create ns cert-manager
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --set installCRDs=true --wait

kubectl create ns cattle-system
helm upgrade --install rancher rancher-latest/rancher -n cattle-system --set hostname=rancher.192.168.1.12.xip.io --set replicas=1 --wait

kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml