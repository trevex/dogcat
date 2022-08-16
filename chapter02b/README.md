
# Setup build environment CI/CD for our game

gcloud config set project nvoss-dogcat-chapter-02-shared
gcloud source repos create dogcat
## e.g.
remember: gcloud init && git config --global credential.https://source.developers.google.com.helper gcloud.sh
git remote add chapter02b $(gcloud source repos describe dogcat --format "value(url)")


## TODO
- Use Config Connector to setup triggers and deploy
