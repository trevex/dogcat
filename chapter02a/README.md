# Chapter 2A (alias `chapter02a`)

In this chapter we change perspective and set up the internal developer platform
and processes as provided by the Platform-Team.


## Prerequisites

You will need the following CLI tools installed and available:
```bash
gcloud (includes gsutil)
terraform
kubectl
base64
```
__NOTE__: The above tools are assumed to be GNU-variants if applicable.

This guide does not go into detail how to set up a public domain.
A public domain has to be set up with its zone configured in another Google Cloud project.
The sub-zone will be created for each cluster/project.

The internal platform services, such as ArgoCD and Tekton, will be hosted under sub-domains of this public domain,
but will be protected by an Identity-Aware Proxy (IAP), which will restrict access to the domain outside of your organization.

## Fork `dogcat-applications`

__TODO__


## Projects

Before we start we need four projects:
1. One project that is referred to as `shared`-project containing CI/CD and other central services.
2. A project for the development environment (`dev`)
3. Finally a project for the production environment (`prd`). 

__NOTE__: We do not create a staging environment as little value is added for the purpose of this demo, but this is most likely something desirable in a real world scenario.

__TODO__: insert diagram

You can create the projects using the CLI. Adapt your `PROJECT_BASENAME` and `REGION` as required:
```bash
cd chapter02a
export PROJECT_BASENAME="nvoss-dogcat-ch02"
export REGION="europe-west3"
gcloud projects create ${PROJECT_BASENAME}-shared --labels=environment=shared
gcloud projects create ${PROJECT_BASENAME}-dev --labels=environment=dev
gcloud projects create ${PROJECT_BASENAME}-prd --labels=environment=prd

# Produces output as follows (will take a minute):
Create in progress for [https://cloudresourcemanager.googleapis.com/v1/projects/nvoss-dogcat-ch02-shared].
Waiting for [operations/cp.5589693136193213439] to finish...done.
Enabling service [cloudapis.googleapis.com] on project [nvoss-dogcat-ch02-shared]...
[...]
```

Before continuing [check if the correct billing account is attached](https://cloud.google.com/billing/docs/how-to/modify-project)
to the projects you just created.

If the billing account is correctly attached, we can start creating resources.


## Bucket for `terraform` state

We want to use remote state with terraform. We need a GCS-Bucket for this.
GCS supports atomic operations and therefore the bucket will both act as lock
as well as state backend.

Using the variables defined above, you can create the bucket as follows:
```bash
gsutil mb -p ${PROJECT_BASENAME}-shared -l ${REGION} -b on gs://${PROJECT_BASENAME}-tf-state
gsutil versioning set on gs://${PROJECT_BASENAME}-tf-state
# Make sure terraform is able to use your credentials (only required if not already the case)
gcloud auth application-default login --project ${PROJECT_BASENAME}-shared
```


## Update `terraform` code

Some values can not be variables in `terraform` such as values used in backend
configurations, so we have to update them by other means.

You can either open all `environments/*/main.tf`-files and update the name of the bucket
to match the bucket created earlier or use a command such as (requires `ripgrep`, GNU-`xargs`, GNU-`sed`):
```bash
rg -l 'backend "gcs"' | xargs -I{} sed -i "s/nvoss-dogcat-ch02-tf-state/${PROJECT_BASENAME}-tf-state/g" {}
```

Next you will have to update the terraform variables, that are set.
Open each `environments/*/*.auto.tfvars`-file and update the variables
to match your projects, region and DNS-settings.
The comments in the files may assist you.


## TODO Roll out first cluster
cluster + crossplane

## Bootstrap ArgoCD
login to cluster
update config
-> app of apps repo
-> cert-manager project ids
kubectl apply -k dogcat-applications/config/argocd



## Roll out the first cluster

Now let's start with the `shared`-cluster, which is were most of the tools
of the internal developer platform are hosted.
First we do a targeted rollout to provision our GKE cluster:
```bash
terraform -chdir=environments/shared init
terraform -chdir=environments/shared apply -target="module.cluster"
```

__NOTE__: If you want to get a better of what is happening in the code, it is recommended to read the code as it was heavily commented for this purpose. Some short-cuts were taken for the purpose of this demo. A production-ready set up would most likely utilize `terragrunt` or `terramate`.


## Org-Policies (optional)

GKE Autopilot clusters require serial port logging to be effectively debugged, check the [documentation for details](https://cloud.google.com/kubernetes-engine/docs/troubleshooting/troubleshooting-autopilot-clusters#scale-up-failed-serial-port-logging).
If your organization uses organizational policies, you might have to make sure it is not enforced in those projects:
```bash
for ENV in shared dev stg prd; do
  gcloud services enable --project ${PROJECT_BASENAME}-${ENV} orgpolicy.googleapis.com
  gcloud beta resource-manager org-policies disable-enforce compute.disableSerialPortLogging --project=${PROJECT_BASENAME}-${ENV}
  gcloud compute project-info add-metadata --project=${PROJECT_BASENAME}-${ENV} --metadata serial-port-logging-enable=true
done
```


## Connecting to the cluster
To connect to the cluster (with the new authentication plugin) run:
```bash
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
gcloud container clusters get-credentials cluster-shared --region ${REGION} --project ${PROJECT_BASENAME}-shared
```


## Rollout platform services 

In the cluster there is currently not much running, but this is about to change.
Apply the `terraform` code once more without a target to deploy everything you need to continue with ArgoCD and Tekton:
```bash
terraform -chdir=environments/shared apply
```

## Accessing ArgoCD UI and Tekton Dashboard

The platform services are rolled out, but it might still take a while until
the changes are properly reconciled in your Kubernetes-cluster.
`cert-manager` will create the TLS-certificate for the Load-Balancers and 
`external-dns` will set up the DNS records for the services.

You can watch the events happening in your cluster with:
```bash
kubectl get events --all-namespaces -w
```

If you are impatient you can also port-forward the services, but once the dust settles 
the services will be available under the in terraform configured domains protected by IAP.

When you access ArgoCD it will ask you to login.
You can use the inbuilt initial admin user, which for the purpose of this demo, we will keep using.

You can retrieve the password for the user `admin` as follows:
```bash
kubectl get secrets -n argo-cd argocd-initial-admin-secret --template={{.data.password}} | base64 --decode
```

In the ArgoCD UI you should already see an application that deploys shared tekton tasks to the cluster.

__TODO__: Add some screenshots

The tekton dashboard is a read-only view and does not require authentication other than required by the IAP.

__TODO__: Add some screenshots

There are already some tekton resources that were created by terraform and ArgoCD.
Terraform configured an event listener that we will use with our Github repository and
ArgoCD already went ahead and deployed some shared tekton tasks from our `dogcat-applications` repository.


## Let's roll out our application clusters

Three application environments exist:
- `dev` is the development environment containing the lastest changes from the master-branch
- `stg` is the staging environment for the tracking releases such as release candidates
- `prd` is the production environment for the latest stable releases and versions

While in theory you can run less commands it is *recommended* to run the following
commands in-sequence (if you want to run them non-interactively append `-auto-approve` to the apply commands):
```bash
terraform -chdir=environments/dev init
terraform -chdir=environments/stg init
# terraform -chdir=environments/prd init
terraform -chdir=environments/dev apply -target="module.cluster"
terraform -chdir=environments/stg apply -target="module.cluster"
# terraform -chdir=environments/prd apply -target="module.cluster"
terraform -chdir=environments/dev apply -target="module.external_dns"
terraform -chdir=environments/stg apply -target="module.external_dns"
# terraform -chdir=environments/prd apply -target="module.external_dns"
terraform -chdir=environments/dev apply -target="module.cert_manager"
terraform -chdir=environments/stg apply -target="module.cert_manager"
# terraform -chdir=environments/prd apply -target="module.cert_manager"
terraform -chdir=environments/dev apply -target="module.kyverno"
terraform -chdir=environments/stg apply -target="module.kyverno"
# terraform -chdir=environments/prd apply -target="module.kyverno"
terraform -chdir=environments/dev apply -target="module.crossplane"
terraform -chdir=environments/stg apply -target="module.crossplane"
# terraform -chdir=environments/prd apply -target="module.crossplane"
terraform -chdir=environments/dev apply
terraform -chdir=environments/stg apply
# terraform -chdir=environments/prd apply
```
The primary reason for this is the gradual rollout of CRDs to allow the controlplane and nodes to scale up.
While some controller have less CRDs, Crossplane creates at least 200. A cluster and its controlplane at minimal scale will not be able to handle it.
There is work undertaken both on the kubernetes- and crossplane-side to mitigate this (see [issue](https://github.com/crossplane/crossplane/issues/3754)).

There is a chance Crossplane is still applying CRDs when you run the last command, greeting you with an error such as:
```
no matches for kind "ProviderConfig" in version "gcp.upbound.io/v1beta1"
```
If this is the case simply run the `terraform apply` again a few minutes later.



__TODO__: Other clusters...


__TODO__: Policies

## Retrospective

- Team pushed terraform to the limits in regards to managing kubernetes resources and should consider moving as much as possible to ArgoCD
- Terraform modules are not using git references
- While the team is implementing some policing, it can make since to audit the state, there are some additional OSS tools that might accomodate their needs: https://forsetisecurity.org/ https://cloudcustodian.io/ https://www.cloudquery.io/ or alternatively asset inventory
- GKE clusters would be more secure with private control-plane
- Backstage would be a nice addition not covered
- ArgoCD permissions should be limited

## Addendum

- Using Argo CD and Tekton with private repositories
- Terraform CI/CD is omitted to keep the demo simple, but https://cloud.google.com/docs/terraform/resource-management/managing-infrastructure-as-code can be used as starting point, consider also using dagger and leverage tflint, tfsec and checkov.
- ConfigConnector or ConfigController can be simpler way to get starting managing Google Cloud resources from within Kubernetes

