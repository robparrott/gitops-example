# Overview

An example setup for starting to leverage GitOps using ArgoCD (https://argocd.io/) on Kubernetes (http://k8s.io/) running in AWS on EKS.

This example, coupled with its companion repository https://github.com/robparrott/k8s-gitops, provide a reference of how to establish a GitOps pattern for deploying applications to Kubernetes from a known state captured fully declaratively as infrastructure as code. Changes to the subscribed-to repositories in this model are pushed automatically to one or more 

# Prerequisites

Besides a basic understanding of DevOps patterns, and some enthusiasm and curiousity, you'll need:

* Suitable rights to create resources in AWS.
* Local installation of the eksctl tool (https://eksctl.io/)
* Local installation of the kubernetes clients (kubectl, kubeconfig)
* Git 


# Infrastructure 

## Create EKS Cluster
```
eksctl create cluster -f eksctl/eksctl-cluster.yaml
```

## Scaling Manually

Determine the relevant nodegroup name (should be the name from the yaml file):
```
eksctl get nodegroup \
        --region=us-east-2 \
        --cluster=sandbox
```

And then scale up or down:

```
eksctl scale nodegroup \
        --region=us-east-2 \
        --cluster=sandbox \
        --name=general \
        --nodes=6
```

## Create using terraform

_This is a work in progress so buyer beware..._

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


# Enable GitOps

## Install ArgoCD 

Integrate with ArgoCD (https://argocd.io/) by installing Argo into its own namespace:

```
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

At this point, you have an unconfigured installation of the GitOps CD tool. You can proceed with automation or setup remote access.

## Setup Remote User Access

Once installed, you can follow any steps here: https://argoproj.github.io/argo-cd/getting_started/ like setting up passwords and the command line client (but note this step is optional, and you can push ahead with the automation for now as well).

In particular, you can get the default initial password, which is the pod name:

```
kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2
```

You can access the web interface by port forwarding the argocd service:

```
 kubectl port-forward svc/argocd-server -n argocd 9443:443
```


Login with this password, with username `admin` to the local URL:

* https://localhost:9443/


## Enable Automation

While you can us the web interface or CLI to configure, it's easier to use automation. At this point the application is installed but unconfigured.  To bind the cluster to a GitOps repository for automation, initialize it against the companion repository by running:

```
kubectl apply -n argocd -f ./argocd/argocd.yaml 
```

This installs a ConfigMap in the `argocd` namespace with a specific configuration that binds to this repository, and to the companion repository.

From this particular repository, it will manage the `argocd` namespace and application, so you can use this repository to do upgrades in the future by editing `argocd/kustomization.yaml` to change the "base" version.

It also enables a very simple "application" that is a set of links to application in the compnaion repository.


# Tailing Logs 

You can get the `kail` tool to selectively tail logs from pods locally:

* https://github.com/boz/kail

# Remote Shell

Simple remote shell can be executed by running `./bin/remote-shell`. This creates an Ubunta box ... install bits and pieces there using `apt install ____`


# Dealing with troublesome finalizers:


To clean up *namespaces* that will not delete (and don't have stuck resources):
```
for ns in $(kubectl get ns --field-selector status.phase=Terminating -o jsonpath='{.items[*].metadata.name}'); do  kubectl get ns $ns -ojson | jq '.spec.finalizers = []' | kubectl replace --raw "/api/v1/namespaces/$ns/finalize" -f -; done
```

for other objects:

```
kubectl patch app APPNAME  -p '{"metadata": {"finalizers": []}}' --type merge
```

