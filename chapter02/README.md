
```bash
gsutil mb -p nvoss-dogcat-chapter-02-shared -l europe-west1 -b on gs://nvoss-dogcat-chapter-02-tf-state
gcloud auth application-default login
terraform -chdir=terraform/dev init 
```

# TODO

- add terraform lockfiles
