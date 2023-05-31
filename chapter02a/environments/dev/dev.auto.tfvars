# The project you created: "${PROJECT_BASENAME}-dev":
project = "nvoss-dogcat-ch02-dev"
# The region you are working in "${REGION}":
region = "europe-west3"

# The cluster will also manage a DNS-zone, so a pre-existing DNS-zone managed
# by Google Cloud is required (as described in the prerequisites).
# The project-name, zone-name of the "parent"-zone are required and the desired
# FQDN for dedidcated zone are required:
dns_project        = "nvoss-demo-dns"
dns_zone_name      = "nvoss-demo"
dns_dedicated_fqdn = "dev.dogcat.nvoss.demo.altostrat.com."

# We protect our platform-services with IAP, so specify a fitting
# trusted domain and support email for the OAuth-Client.
# All users belonging to the trusted domain will have access to the IAP protected
# services.
iap_access_domain = "nvoss.altostrat.com" # e.g. myuser@nvoss.altostrat.com will have access
iap_support_email = "admin@nvoss.altostrat.com"

# Crossplane is setup by terraform and compositions using terraform are set up
crossplane_version                    = "v1.12.1" # chart-version
crossplane_provider_terraform_version = "v0.7.0"

# The `artifact_repository_id` and `(shared_)cluster_id` are outputs of the shared
# terraform environment, e.g.:
# `terraform -chdir=environments/shared output`
# Alternatively they can be deduced based on your project name and region!
artifact_repository_id = "projects/nvoss-dogcat-ch02-shared/locations/europe-west3/repositories/images"
shared_cluster_id      = "projects/nvoss-dogcat-ch02-shared/locations/europe-west3/clusters/cluster-shared"

# For this cluster an instantiation of apps-of-apps is used, so let's specify
# our fork of the applications repository.
argo_cd_applications_repo_url = "git@github.com:NucleusEngineering/dogcat-applications.git"
argo_cd_sync_policy_automated = true
