---
title: Kubernetes RBAC
categories:
  - Kubernetes
---

## Introduction

### 1) RBAC Four API Objects

- Role: A collection of permissions within a namespace, used to define a role that can only authorize resources within the namespace. For cluster-level resources, ClusterRole is required. Example: defining a role to read Pods
- ClusterRole: Has the same namespace resource management capabilities as Role, and can also authorize the following special elements:
  - Cluster-wide resources, such as Nodes
  - Non-resource paths, such as /healthz
  - Resources across all namespaces, such as Pods
    > Example: defining a cluster role that allows users to access any secrets
- RoleBinding: Binds a role to subjects
- ClusterRoleBinding: Binds a cluster role to subjects
  > RoleBinding and ClusterRoleBinding are used to bind a role to a target, which can be a User, Group, or Service Account. Use RoleBinding to authorize within a specific namespace, and ClusterRoleBinding to authorize cluster-wide.

**Role and ClusterRole define permission rules**

- rules represent specific authorization rules, similar to permission policies (Policy) in Alibaba Cloud RAM
- The only difference between Role and ClusterRole is that one is for cluster-level resource control

**RoleBinding and ClusterRoleBinding bind Users, Groups, and ServiceAccounts to Roles or ClusterRoles (similar to assigning Policies to RAM roles or RAM accounts in Alibaba Cloud RAM)**

- User, Group, and ServiceAccount are independent concepts in a Kubernetes cluster, different from system-level concepts. Reference: [https://www.qikqiak.com/k8strain2/security/rbac/#%E5%88%9B%E5%BB%BA%E8%A7%92%E8%89%B2](https://www.qikqiak.com/k8strain2/security/rbac/#%E5%88%9B%E5%BB%BA%E8%A7%92%E8%89%B2)
- A RoleBinding can reference any Role in the same namespace; or a RoleBinding can reference a ClusterRole and bind that ClusterRole to the namespace where the RoleBinding resides.
- To bind a ClusterRole to all namespaces in the cluster, ClusterRoleBinding must be used
- A RoleBinding can reference a ClusterRole object to grant users access to namespace resources defined in the referenced ClusterRole within the namespace where the RoleBinding resides. (Define a set of common roles across the entire cluster, then reuse these roles in different namespaces)

### 2) Resource Reference Methods

- Most resources can be represented by their name strings, which are the relative URL paths in the Endpoint, e.g., pod logs are GET /api/v1/namespaces/{namespace}/pods/{podname}/log
- If you need to represent sub-resources within an RBAC object, use "/" to separate the resource and sub-resource.

Example: To authorize a subject to read both Pods and Pod logs, configure resources as an array

```yaml
rules:
- apiGroups: [""]
   resources: ["pods","pods/log"]
   verbs: ["get","list"]
```

- Reference by name (ResourceName). After specifying a ResourceName, get, delete, update, and patch requests will be restricted to that specific resource instance

Example: The following declaration allows a subject to only perform get and update operations on the ConfigMap named my-configmap:

```yaml
rules:
- apiGroups: [""]
   resources: ["configmap"]
   resourceNames: ["my-configmap"]
   verbs: ["get","update"]
```

### 3) rules Parameter Descriptions

- apiGroups: List of supported API groups, e.g., "apiVersion: batch/v1", etc.
- resources: List of supported resource objects, e.g., pods, deployments, jobs, etc.
- resourceNames: Specifies the resource name (optional)
- verbs: List of operations on resource objects
  > api-resources: all resource information
  > apiGroups: category groups under api-resources
  >
  > [View API GROUP Information](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.23/#-strong-api-groups-strong-)
  >
  > - Method 1: kubectl explain xxx, where xxx is the NAME value from the "kubectl api-resources" output (if the VERSION value is v1, it belongs to the default Core API group, represented by "", e.g., pods, services)
  > - Method 2: kubectl get --raw /apis/apps/v1

You can get information about the four RBAC API resource objects via `kubectl get --raw /apis/rbac.authorization.k8s.io/v1`, as shown below:

```bash
$ kubectl get --raw  /apis/rbac.authorization.k8s.io/v1
{"kind":"APIResourceList","apiVersion":"v1","groupVersion":"rbac.authorization.k8s.io/v1","resources":[{"name":"clusterrolebindings","singularName":"clusterrolebinding","namespaced":false,"kind":"ClusterRoleBinding","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"storageVersionHash":"48tpQ8gZHFc="},{"name":"clusterroles","singularName":"clusterrole","namespaced":false,"kind":"ClusterRole","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"storageVersionHash":"bYE5ZWDrJ44="},{"name":"rolebindings","singularName":"rolebinding","namespaced":true,"kind":"RoleBinding","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"storageVersionHash":"eGsCzGH6b1g="},{"name":"roles","singularName":"role","namespaced":true,"kind":"Role","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"storageVersionHash":"7FuwZcIIItM="}]}

```

> Methods for creating resources/information
>
> - Method 1: kubectl create -f xxx.yaml --> Create via file
> - Method 2: kubectl create --arg1=xxx --arg2=yyy --> Create via parameters (can be further edited using kubectl edit)

## ServiceAccount Testing

### 1) Create a ServiceAccount and Assign Permissions

1. Create a serviceaccount named example-sva (only the default namespace is needed)
   Command: kubectl create serviceaccount example-sva -n default

2. Create a role (granting CRUD permissions for Integration, Kamelet, and KameletBinding resources)
   Command: kubectl create role example-sva-role --verb=\* --resource=integrations,kamelets,kameletbindings

3. Bind cluster permissions
   Command: kubectl create rolebinding example-sva-rolebinding --role=example-sva-role --serviceaccount=default:example-sva

4. View account secret information
   Command: kubectl get secret/example-sva-token-mdt28 -oyaml
   After base64 decoding the obtained token value, it can be used to call the apiserver API. The API endpoints can be retrieved via `kubectl get --raw /apis/`:

### 2) Create a User-Authenticated kubeconfig File

1. Create the cluster configuration file
   Command: kubectl config set-cluster kubernetes --certificate-authority=/etc/kubernetes/pki/ca.crt --server="https://10.0.0.142:6443" --embed-certs=true --kubeconfig=./example-sva.conf

2. Generate the token (base64 encoded)
   Command: D=$(kubectl get secret example-sva-token-mdt28 -o jsonpath={.data.token}|base64 -d)

3. Add token information to the configuration file, setting a user entry
   Command: kubectl config set-credentials example-sva --token=$D --kubeconfig=./example-sva.conf

4. Add permission information to the configuration file, setting a context entry
   kubectl config set-context example-sva@kubernetes --cluster=kubernetes --user=example-sva --kubeconfig=./example-sva.conf

5. Add permission information to the configuration file, setting the current context
   Command: kubectl config use-context example-sva@kubernetes --kubeconfig=./example-sva.conf

After executing the above commands, the configuration file example-sva.conf is generated in the current directory. It can be copied to the kubeconfig directory for use.
Using this configuration file with kubectl commands, you can verify that the user only has permissions to operate on the corresponding resources.

### 3) API Object Structure

> Reference:
>
> 1. [https://kubernetes.io/zh/docs/reference/access-authn-authz/rbac/#service-account-permissions](https://kubernetes.io/zh/docs/reference/access-authn-authz/rbac/#service-account-permissions)
> 2. [https://www.qikqiak.com/k8strain2/security/rbac/#%E5%88%9B%E5%BB%BA%E8%A7%92%E8%89%B2](https://www.qikqiak.com/k8strain2/security/rbac/#%E5%88%9B%E5%BB%BA%E8%A7%92%E8%89%B2)
> 3. [https://zhuanlan.zhihu.com/p/97793056](https://zhuanlan.zhihu.com/p/97793056)
