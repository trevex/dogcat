Prerequisites:

```bash
gcloud (includes gsutil)
terraform
kubectl
base64
```

- Another Google-Project with a working public DNS-zone!

```bash
cd chapter02a
export PROJECT_BASENAME="nvoss-dogcat-chapter02"
export REGION="europe-west3"
gcloud projects create ${PROJECT_BASENAME}-shared --labels=environment=shared
gcloud projects create ${PROJECT_BASENAME}-dev --labels=environment=dev
gcloud projects create ${PROJECT_BASENAME}-stg --labels=environment=stg
gcloud projects create ${PROJECT_BASENAME}-prd --labels=environment=prd

# Produces output as follows (will take a minute):
Create in progress for [https://cloudresourcemanager.googleapis.com/v1/projects/nvoss-dogcat-chapter02-shared].
Waiting for [operations/cp.5589693136193213439] to finish...done.
Enabling service [cloudapis.googleapis.com] on project [nvoss-dogcat-chapter02-shared]...
[...]
```

Before continuing check if the correct billing account is attached to the projects
you just created.
https://cloud.google.com/billing/docs/how-to/modify-project

If the billing account is correctly attached, we can start creating resources.
We need a bucket to store the terraform state before we can provision resources
with terraform:

```bash
gsutil mb -p ${PROJECT_BASENAME}-shared -l ${REGION} -b on gs://${PROJECT_BASENAME}-tf-state
gsutil versioning set on gs://${PROJECT_BASENAME}-tf-state
# Make sure terraform is able to use your credentials (only required if not already the case)
gcloud auth application-default login --project ${PROJECT_BASENAME}-shared
```

There terraform code will try to use the currently configured backend, which
will not use your bucket, so we first have to update those.

You can either open all `environments/*/main.tf`-files and update the bucket-name
referenced in the backend-definition at the top of the file or use a command such as
(requires `ripgrep`, `xargs`, `sed`):

```bash
rg -l 'backend "gcs"' | xargs -I{} sed -i "s/nvoss-dogcat-chapter02-tf-state/${PROJECT_BASENAME}-tf-state/g" {}
```

Next you will have to update the terraform variables, that are set.
Open each `environments/*/*.auto.tfvars`-file and update the variables
to match your projects, region and DNS-settings.
The comments in the files may assist you.

Now let's start with the shared-cluster, which is were most of the tools
of the internal developer platform are hosted.
First we do a targeted rollout to provision our GKE cluster:
```bash
terraform -chdir=environments/shared apply -target="module.cluster"
```

## Argolis / Org-Policies

GKE Autopilot clusters require serial port logging to be effectively debugged.
Check the documentation for more information:
https://cloud.google.com/kubernetes-engine/docs/troubleshooting/troubleshooting-autopilot-clusters#scale-up-failed-serial-port-logging
Make sure the organization policy is not enforced:

```
for ENV in shared dev stg prd; do
  gcloud services enable --project ${PROJECT_BASENAME}-${ENV} orgpolicy.googleapis.com
  gcloud beta resource-manager org-policies disable-enforce compute.disableSerialPortLogging --project=${PROJECT_BASENAME}-${ENV}
  gcloud compute project-info add-metadata --project=${PROJECT_BASENAME}-${ENV} --metadata serial-port-logging-enable=true
done
```


To connect to the cluster (with the new authentication plugin) run:
```bash
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
gcloud container clusters get-credentials cluster-shared --region ${REGION} --project ${PROJECT_BASENAME}-shared
```

In the cluster there is currently not much running, but this is about to change.
Apply the terraform-code once more to deploy everything you need to continue with ArgoCD:
```bash
terraform -chdir=environments/shared apply
```








# Code heavy so make sure to also look at the code and its comments

### Argolis users only
`export SHARED_PROJECT="nvoss-dogcat-chapter-02-shared"`
```bash
$ gcloud services enable --project ${PROJECT_BASENAME}-shared orgpolicy.googleapis.com
Operation "operations/xxx.xxxxxxxxxx" finished successfully.
$ gcloud beta resource-manager org-policies disable-enforce iam.disableServiceAccountKeyCreation --project=$SHARED_PROJECT
booleanPolicy: {}
constraint: constraints/iam.disableServiceAccountKeyCreation
[...]
```

# Create the four projects!!!

```bash
gsutil mb -p nvoss-dogcat-chapter-02-shared -l europe-west1 -b on gs://nvoss-dogcat-chapter-02-tf-state
gsutil versioning set on gs://nvoss-dogcat-chapter-02-tf-state
gcloud auth application-default login
terraform -chdir=environments/shared init 
terraform -chdir=environments/shared apply # explain everything that is created!

kubectl get secrets -n argo-cd argocd-initial-admin-secret --template={{.data.password}} | base64 --decode
terraform -chdir=environments/shared output tekton_trigger_secret # or k8s secret?...
```

```
git remote add applications ssh://admin@nvoss.altostrat.com@source.developers.google.com:2022/p/nvoss-dogcat-chapter-02-shared/r/argo-cd-applications
git push applications main:master # still uses master as head and head is required to test :|
```
INSTEAD
fork `dogcat-applications` as public repo to simplify demo!


Alt: use https://github.com/marketplace/google-cloud-build instead of source repo
==> https://cloud.google.com/architecture/managing-infrastructure-as-code


export USE_GKE_GCLOUD_AUTH_PLUGIN=True
gcloud container clusters get-credentials cluster-shared --region europe-west1 --project nvoss-dogcat-chapter-02-shared


# TODO

Terraform CI/CD omitted but reference: https://cloud.google.com/architecture/managing-infrastructure-as-code
And tools such as tfsec, tflint and checkov 

Teraform should use two branches:
develop => straigth to dev
main => straight to stage, approval for prod and shared (mention no dev setup for shared in retro!)

use gates for shared and prod: https://cloud.google.com/build/docs/securing-builds/gate-builds-on-approval#:~:text=Approving%20builds,-Console%20gcloud&text=Open%20the%20Cloud%20Build%20Dashboard%20page%20in%20the%20Google%20Cloud%20console.&text=If%20you%20have%20builds%20to,of%20builds%20awaiting%20your%20approval.


TODO https://cloud.google.com/anthos-config-management/docs/concepts/policy-controller

TODO split up code to make it more readable

# Retro:

Team is using a very liberal approach as they do not believe in gatekeeping, but have yet to implement some policing and auditing outside of GKE.
They are planning to adopt a tool to help here and are currently looking into some OSS:
https://forsetisecurity.org/
https://cloudcustodian.io/
https://www.cloudquery.io/

Daniel: policy troubleshooter, asset inventory, iam recommender

Team pushed terraform to its max and feels like they have to introduce new tool, e.g. kubectl not optimal
Terraform not using git refs for modules ==> split?
Config Controller VS Config Connector

GKE should be private but needs also private cloud build etc

Kpt and backstage UI mention looks promising

ArgoCD permission in-cluster should be limited

# FUTURE:

 alternative to chapter02b https://cloud.google.com/kubernetes-engine/docs/tutorials/gitops-cloud-build
