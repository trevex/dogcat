
## Tekton

### Add pipeline

TODO: Explain repo mapping...

## Add hook

In shared cluster:
```bash
kubectl get secrets -n tekton tekton-trigger-secret --template='{{ index .data "shared-secret" }}' | base64 --decode
```




# Setup build environment CI/CD for our game

gcloud config set project nvoss-dogcat-chapter-02-shared
gcloud source repos create dogcat
## e.g.
remember: gcloud init && git config --global credential.https://source.developers.google.com.helper gcloud.sh
git remote add chapter02b $(gcloud source repos describe dogcat --format "value(url)")


## deploy
targets created by platform team with correct permissions
so only a delivery pipeline is required
```
gcloud deploy apply --file ./clouddeploy.yaml --region=europe-west1

Waiting for the operation on resource projects/nvoss-dogcat-chapter-02-shared/locations/europe-west1/deliveryPipelines/dogcat...done.
Created Cloud Deploy resource: projects/nvoss-dogcat-chapter-02-shared/locations/europe-west1/deliveryPipelines/dogcat.
```

serviceaccounts created by platform team to use with cloud build

```
gcloud beta builds triggers create cloud-source-repositories \
  --repo dogcat \
  --branch-pattern="^main$" \
  --build-config="chapter02b/cloudbuild.yaml" \
  --description="Build dogcat and deploy to dev from main-branch." \
  --name dogcat-dev \
  --service-account="projects/nvoss-dogcat-chapter-02-shared/serviceAccounts/build-dev@nvoss-dogcat-chapter-02-shared.iam.gserviceaccount.com"
```
https://cloud.google.com/sdk/gcloud/reference/beta/builds/triggers/create/cloud-source-repositories



Use skaffold to deploy manually
```
gcloud auth configure-docker europe-west1-docker.pkg.dev # once
skaffold render -p dev -i dogcat=europe-west1-docker.pkg.dev/nvoss-dogcat-chapter-02-shared/images/dogcat:8dd53bc
```

Skaffold also has dev setup etc not covered, but to deploy manually locally checkout local and adapt image override


# Git flow

Slightly different: Deploy from main to dev, tags with rc to stage, semver without suffix to prod (but approval)



# Retro
Thinking about using Skaffold for build as  well to get more align local == cloud


