#!/bin/sh

set -e

# Install openssl
apk add openssl

# Validate args and set defaults
DEPLOYMENT="${DEPLOYMENT:-"docker-registry"}"
SECRET_NAME="${SECRET_NAME:-"registry-auth-cert"}"
KUBECTL_VERSION="${KUBECTL_VERSION:-"$(wget -O - https://storage.googleapis.com/kubernetes-release/release/stable.txt)"}"

# Install kubectl
wget -O /usr/local/bin/kubectl "https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
chmod +x /usr/local/bin/kubectl

while true; do
  # Sleep if the certificate is more than 2 hours away from expiry
  if openssl x509 -in /etc/tls/tls.crt -noout -checkend 7200 -out /dev/null; then
    sleep 1500 # 25 min
    continue
  fi

  # Rotate the certificate+key
  echo "Creating a new self-signed certificate and key pair for token auth"
  openssl \
    ecparam -out tls.key \
    -name prime256v1 \
    -noout \
    -genkey
  openssl \
    req -x509 \
    -new \
    -key tls.key \
    -days 1 \
    -out tls.crt \
    -subj "/CN=${DEPLOYMENT}"

  # Update the secret
  echo "Updating secret"
  kubectl create secret \
    tls "${SECRET_NAME}" \
    --cert tls.crt \
    --key tls.key \
    --dry-run -o yaml | kubectl apply -f -

  # Restart the deployment to pick up the new key pair
  echo "Restarting ${DEPLOYMENT} deployment"
  kubectl rollout restart deployment "${DEPLOYMENT}"

  echo "Rotated successfully on $(date)"

  # It can take kube a few minutes to update /etc/tls/tls.crt, so sleep now to give that time to happen
  sleep 1500 # 25 min
done