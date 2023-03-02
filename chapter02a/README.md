# cd chapter02a

# Code heavy so make sure to also look at the code and its comments

# Create the four projects!!!

```bash
gsutil mb -p nvoss-dogcat-chapter-02-shared -l europe-west1 -b on gs://nvoss-dogcat-chapter-02-tf-state
gsutil versioning set on gs://nvoss-dogcat-chapter-02-tf-state
gcloud auth application-default login
terraform -chdir=environments/shared init 
terraform -chdir=environments/shared apply # explain everything that is created!

kubectl get secrets argocd-initial-admin-secret --template={{.data.password}} | base64 --decode
```

```
git remote add chapter02a ssh://admin@nvoss.altostrat.com@source.developers.google.com:2022/p/nvoss-dogcat-chapter-02-shared/r/infrastructure
```

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

# FUTURE:

 alternative to chapter02b https://cloud.google.com/kubernetes-engine/docs/tutorials/gitops-cloud-build
