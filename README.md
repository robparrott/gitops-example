# Overview

An example setup for starting gitOps using ArgoCD (https://argocd.io/) on Kubernetes (http://k8s.io/).

# Prerequisites

Suitable rights to create resources

# Infrastructure 

## Create EKS Cluster
```
eksctl create cluster -f eksctl-cluster.yaml
```

## Create using terraform

See:

* https://github.com/terraform-aws-modules/terraform-aws-eks/tree/master/examples
* https://github.com/terraform-providers/terraform-provider-aws/tree/master/examples/eks-getting-started
* https://medium.com/tensult/guide-to-setup-kubernetes-in-aws-eks-using-terraform-and-deploy-sample-applications-ee8c45e425ca

```
cd terraform
terraform init
terraform plan
terraform apply
```

Enable kubectl to access this via:

```
aws eks update-kubeconfig --region us-west-2 --name k8s-sandbox
```

## Scaling Manually

Determine the relevant nodegroup name (should be the name from the yaml file):
```
eksctl get nodegroup \
        --region=us-east-2 \
        --cluster=parrott-confluent-kafka
```

And then scale up or down:

```
eksctl scale nodegroup \
        --region=us-east-2 \
        --cluster=parrott-confluent-kafka \
        --name=general \
        --nodes=6
```


# Enable GitOps

Integrate with ArgoCD (https://argocd.io/) by installing Argo into its own namespace:

```
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

and steps here: https://argoproj.github.io/argo-cd/getting_started/

Initialize against this repo:

```
kubectl apply -n argocd -f ./argocd/argocd.yaml 
```

And then port forward the argocd web interface:

```
 kubectl port-forward svc/argocd-server -n argocd 8080:443
```

get the default initial password:

```
kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2
```

Login with this password, with username `admin`.



# Tailing Logs 

You can get the `kail` tool to selectively tail logs from pods locally:

* https://github.com/boz/kail

# Forwarding Services:

Vault:


Kubernetes Dashboard:

```
kubectl port-forward service/kube-dashboard-kubernetes-dashboard -n kube-system 8443:443 
```

## Getting the cluster admin bearer token

Service Account "eks-admin" has a bearer token for access, so you need to dig that out to access Kubernetes Dashboard:

```
SECRET=$(kubectl -n kube-system get secret | grep eks-admin-token | awk '{print $1}')
TOKEN=$( kubectl -n kube-system describe secret ${SECRET} | grep "^token:" | awk '{print $2}' )
echo $TOKEN
```



