
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


# Git flow

Slightly different: Deploy from main to dev, tags with rc to stage, semver without suffix to prod (but approval)

https://www.googleapis.com/download/storage/v1/b/configconnector-operator/o/1.91.0%2Frelease-bundle.tar.gz?generation=1659639822503508&alt=media
https://www.googleapis.com/download/storage/v1/b/configconnector-oper:ator/o/1.91.0%2Frelease-bundle.tar.gz?generation=1659639822503508&alt=media
