# Chapter 2A (alias `chapter02a`)

In this chapter we change perspective and set up the internal developer platform
and processes as provided by the Platform-Team.

## Team-Background

__TODO___



## Prerequisites

You will need the following CLI tools installed and available:
```bash
gcloud (includes gsutil)
terraform
kubectl
base64
ripgrep
xargs
sed
```
__NOTE__: The above tools are assumed to be GNU-variants if applicable. If you only have the BSD-variants available, you might have to update some commands in this code or install them.

This guide does not go into detail how to set up a public domain.
A public domain has to be set up with its zone configured in another Google Cloud project. 
This zone does not have to be a TLD. For the purpose of this demo the zone `dogcat.nvoss.demo.altostrat.com` was preconfigured.
For each cluster/project a sub-zone will be created.

The internal platform services, such as ArgoCD and Tekton, will be hosted under sub-domains of this public domain,
but will be protected by an Identity-Aware Proxy (IAP), which will restrict access to the domain outside of your organization.

## Org-Policies (optional)

GKE Autopilot clusters require serial port logging to be effectively debugged, check the [documentation for details](https://cloud.google.com/kubernetes-engine/docs/troubleshooting/troubleshooting-autopilot-clusters#scale-up-failed-serial-port-logging).
If your organization uses organizational policies, you might have to make sure it is not enforced in those projects:
```bash
for ENV in shared dev; do
  gcloud services enable --project ${PROJECT_BASENAME}-${ENV} orgpolicy.googleapis.com
  gcloud beta resource-manager org-policies disable-enforce compute.disableSerialPortLogging --project=${PROJECT_BASENAME}-${ENV}
  gcloud compute project-info add-metadata --project=${PROJECT_BASENAME}-${ENV} --metadata serial-port-logging-enable=true
done
```

## Fork `dogcat` and `dogcat-applications`

For the purpose of this demo, please go ahead and fork both the [dogcat](https://github.com/NucleusEngineering/dogcat)- and [dogcat-applications](https://github.com/NucleusEngineering/dogcat-applications)-repositories.

While the the [dogcat](https://github.com/NucleusEngineering/dogcat)-repository is the primary repository
containing the application code and terraform code as well as the documentation, the [dogcat-applications](https://github.com/NucleusEngineering/dogcat-applications)-repository is the entrance point for the GitOps processes implemented by ArgoCD.

## Projects

Before we start we need two projects:
1. One project that is referred to as `shared`-project containing CI/CD and other central services.
2. A project for the development environment (`dev`)

__NOTE__: We do not create a staging- or production-environment as little value is added for the purpose of this demo and keeps cost down, but this is most likely something desirable in a real world scenario.

You can create the projects using the CLI. Adapt your `PROJECT_BASENAME` and `REGION` as required:
```bash
cd chapter02a
export PROJECT_BASENAME="nvoss-dogcat-ch02"
export REGION="europe-west3"
gcloud projects create ${PROJECT_BASENAME}-shared --labels=environment=shared
gcloud projects create ${PROJECT_BASENAME}-dev --labels=environment=dev

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

Now before you roll out the terraform code to provision the basic infrastructure,
you'll have to do some updates.

Some values can not be variables in `terraform` such as values used in backend
configurations, so we have to update them by other means.

You can either open all `environments/{shared,main}/main.tf`-files and update the name of the bucket
to match the bucket created earlier or use a command such as (requires `ripgrep`, GNU-`xargs`, GNU-`sed`):
```bash
rg -l 'backend "gcs"' | xargs -I{} sed -i "s/nvoss-dogcat-ch02-tf-state/${PROJECT_BASENAME}-tf-state/g" {}
```

Next you will have to update the terraform variables, that are set.
Start with `environments/shared/shared.auto.tfvars` and update the variables.
The comments in the file may assist you.
We will tackle `environments/dev/dev.auto.tfvars` once the shared environment is setup.

## Roll out the shared cluster

Now let's start with the `shared`-cluster, which is were most of the tools
of the internal developer platform are hosted.
First we do a targeted rollout to provision our GKE cluster:
```bash
terraform -chdir=environments/shared init
terraform -chdir=environments/shared apply -target="module.cluster"
terraform -chdir=environments/shared apply
```

We use two steps as some terraform resources depend on the cluster being available.

__NOTE__: If you want to get a better of what is happening in the code, it is recommended to read the code as it was heavily commented for this purpose. Some short-cuts were taken for the purpose of this demo. A production-ready set up would most likely utilize `terragrunt` or `terramate`.

## Bootstrap ArgoCD

Now the terraform code is fairly minimal and only is responsible for cloud infrastructure and
managing Crossplane and the platform team's compositions.
To deploy the rest of the services to the Kubernetes cluster, ArgoCD is used.

After bootstrapping ArgoCD is managing itself from the `dogcat-applications`-repository
and deploy all other services following ArgoCD declarative "App of Apps"-paradigm.

### Update configuration

Let's go to the `dogcat-applications`-repository and update the configuration.
Several replacements are required to update the configuration with your designated values.

Before executing any commands make sure the `REGION` and `PROJECT_BASENAME` environment variables are available.

1. We update the project names and region where required:
```bash
rg -l 'europe-west3' | xargs -I{} sed -i "s/europe-west3/${REGION}/g" {}
rg -l 'nvoss-dogcat-ch02' | xargs -I{} sed -i "s/nvoss-dogcat-ch02/${PROJECT_BASENAME}/g" {}
```

2. Cert-manager uses Let's Encrypt to issue certificates automatically, an email is required to create the issuer. Make sure to replace or provide `${YOUR_EMAIL}` in the following command:
```bash
rg -l 'nvoss@google.com' | xargs -I{} sed -i "s/nvoss@google\.com/${YOUR_EMAIL}/g" {}
```

3. Tekton and ArgoCD are exposed under a public domain in the related sub-zone, so make sure to update them. Make sure to replace or provider `${YOUR_ZONE}` in the following command:
```bash
rg -l 'dogcat.nvoss.demo.altostrat.com' | xargs -I{} sed -i "s/dogcat\.nvoss\.demo\.altostrat\.com/${YOUR_ZONE}/g" {}
```

4. Lastly, we need to update the references to the repositories to your forks, so update the organization-/user-part of the repository references. Make sure to replace or provide `${YOUR_GITBASE}` in the following commands:
```bash
rg -l 'git@github.com:NucleusEngineering' | xargs -I{} sed -i "s/git@github\.com:NucleusEngineering/${YOUR_GITBASE}/g" {}
```

### Deploy ArgoCD

Select the correct context or create and select it by using the following command:
```bash
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
gcloud container clusters get-credentials cluster-shared --region ${REGION} --project ${PROJECT_BASENAME}-shared
```

Test the connection by issuing `kubectl get pods --all-namspaces` and then deploy ArgoCD using kustomize:
```bash
kubectl apply -k config/argocd
```

## Wait for a bit

What happens now might take a moment: ArgoCD is installing components, GKE is 
provisioning new nodes to cover the workload. As cert-manager and external-dns are not immediately available, 
you can port-forward the ArgoCD UI to track what is going:
```bash
kubectl -n argocd port-forward argocd-server-12345678-abcde 8080 # use the correct pod-name
```

Or check the events happening in your cluster:
```bash
kubectl get events --all-namespaces -w
```

__TODO__: Add some screenshots of ArgoCD in action

## Github Webhook for Tekton

__TODO__: screenshot of tekton UI
__TODO__: see sections

### get tekton trigger secret
### setup github webhook

## Dev cluster
-> update config
-> two step rollout again

## Ch02b
-> add repo
-> setup webhook
-> add team
-> add app










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

-> we want to allow argocd image updater to write updates to 
ssh-keygen -t ed25519 -C "nvoss@google.com" -f argocd-image-updater -q -N ""
kubectl -n argocd create secret generic git-applications-write --from-file=sshPrivateKey=./argocd-image-updater
-> use local git creds instead...
cat argocd-image-updater.pub # copy
Github UI (see screenshots)

