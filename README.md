# docker-registry-manifests

This repository provides a Kustomize base for Docker Registry v2, backed by an S3 bucket and with authentication and
authorization provided by [docker_auth](https://github.com/cesanta/docker_auth).

## Usage

Reference the base in your `kustomization.yaml`:

```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
bases:
  - github.com/utilitywarehouse/docker-registry-manifests//base?ref=1.1.0
```

## Example

Build the example:

```
kustomize build example/
```

## Requires

- https://github.com/kubernetes-sigs/kustomize

```
go install sigs.k8s.io/kustomize/kustomize/v3
```
