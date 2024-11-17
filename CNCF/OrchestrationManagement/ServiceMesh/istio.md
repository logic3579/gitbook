---
description: Istio
---

# Istio

## Introduction

### Resource

#### ServiceEntry
```yaml
# cat serviceentry.yaml
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: svc-entry
spec:
  hosts:
  - ext-svc.example.com
  ports:
  - number: 443
    name: https
    protocol: HTTPS
  location: MESH_EXTERNAL
  resolution: DNS

---
# ext destinationrule.yaml
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: ext-res-dr
spec:
  host: ext-svc.example.com
  trafficPolicy:
    connectionPool:
      tcp:
        connectTimeout: 1s
```

#### Sidecar
```yaml
# cat sidecar.yaml
apiVersion: networking.istio.io/v1
kind: Sidecar
metadata:
  name: default
  namespace: bookinfo
spec:
  egress:
  - hosts:
    - "./*"
    - "istio-system/*"
```

#### Gateway
```yaml
# cat gateway.yaml
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: ext-host-gwy
  namespace: istio-system
spec:
  selector:
    app: my-ingressgateway
  servers:
  - hosts:
    - '*.example.com'
    port:
      name: http
      number: 80
      protocol: HTTP
    tls:
      httpsRedirect: false
  - hosts:
    - '*.example.com'
    port:
      name: https
      number: 443
      protocol: HTTPS
    tls:
      credentialName: ext-host-cert
	  mode: SIMPLE
```

#### VirtualService
```yaml
# cat virtualservice.yaml
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  labels:
    app.kubernetes.io/name: my-app
    app.kubernetes.io/version: 0.1.0
  name: bookinfo
  namespace: istio-system
spec:
  # Gateway
  gateways:
  - istio-system/ext-host-gwy


  # TCPRoute
  hosts:
  - mongo.prod.svc.cluster.local
  tcp:
  - match:
    - port: 27017
    route:
    - destination:
        host: mongo.backup.svc.cluster.local
        port:
          number: 5555


  # HTTPMatchRoute
  hosts:
  - book.example.com
  http:
  - match:
    - uri:
        prefix: /reviews
    route:
    - destination:
        host: reviews.istio-system.svc.cluster.local
  - match:
    - uri:
        prefix: /ratings
    route:
    - destination:
        host: ratings.istio-system.svc.cluster.local
  - match:
    - headers:
        end-user:
          exact: jason
      uri:
        prefix: /ratings
    route:
    - destination:
        host: ratings.istio-system.svc.cluster.local
        subset: v2
  # default destination route
  - route:
    - destination:
        host: default-service.istio-system.svc.cluster.local
        

  # HTTPRouteDestination
  hosts:
  - canary.prod.svc.cluster.local
  http:
  - route:
    - destination:
        host: canary.prod.svc.cluster.local
        subset: v2
      weight: 25
    - destination:
        host: canary.prod.svc.cluster.local
        subset: v1
      weight: 75


```

#### DestinationRule
```yaml
# cat destinationrule.yaml
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: my-destination-rule
spec:
  host: my-svc
  trafficPolicy:
    loadBalancer:
      simple: RANDOM
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
    trafficPolicy:
      loadBalancer:
        simple: ROUND_ROBIN
  - name: v3
    labels:
      version: v3
```


## Deploy By Container

### Sidecar Mode
####  Install by istioctl
```bash
# Download istioctl
curl -L https://istio.io/downloadIstio | sh -
cd istio-1.23.2
export PATH=$PWD/bin:$PATH

# istioctl
istioctl profile --list
istioctl profile dump demo
istioctl profile diff default stable
istioctl manifest generate > generated-manifest.yaml
istioctl uninstall --purge

# install istio cluster
istioctl install --set meshConfig.accessLogFile=/dev/stdout
kubectl label namespace default istio-injection=enabled
# install Gateway API CRD resource
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
{ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.1.0" | kubectl apply -f -; }
# install Gateway
kubectl apply -f gateway.yml -n istio-system

# uninstall
kubectl delete -f samples/addons
istioctl uninstall -y --purge
kubectl delete namespace istio-system
kubectl label namespace default istio-injection-
kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.1.0" | kubectl delete -f -
```

#### Install by helm
```bash
# add and update repo
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update
kubectl create namespace istio-system

# install istio-base CRD
helm install istio-base istio/base -n istio-system

# install istiod
helm install istiod istio/istiod -n istio-system --wait

# option: install gateway
kubectl create namespace istio-ingress
helm install istio-ingress istio/gateway -n istio-ingress --wait
```

#### Deploy application
```bash
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.23/samples/bookinfo/platform/kube/bookinfo.yaml
kubectl get pods,services
kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
```

#### Outside traffic and access
```bash
# install Gateway
kubectl apply -f samples/bookinfo/gateway-api/bookinfo-gateway.yaml
kubectl annotate gateway bookinfo-gateway networking.istio.io/service-type=ClusterIP --namespace=default
kubectl get gateway

# install VirtualService
kubectl apply -f virtualservice.yaml

# access
kubectl get virtualservice xxx -oyaml
```

### Ambient Mode
```bash
```



> Reference:
> 1. [Official Website](https://istio.io/)
> 2. [Repository](https://github.com/istio/istio)
