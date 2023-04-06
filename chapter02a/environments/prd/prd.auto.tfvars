# The project you created: "${PROJECT_BASENAME}-prd":
project = "nvoss-dogcat-chapter02-prd"
# The region you are working in "${REGION}":
region = "europe-west3"

# The cluster will also manage a DNS-zone, so a pre-existing DNS-zone managed
# by Google Cloud is required (as described in the prerequisites).
# The project-name, zone-name and desired fqdn for dedidcated zone are required:
dns_project        = "nvoss-demo-dns"
dns_zone_name      = "nvoss-demo"
dns_dedicated_fqdn = "prd.dogcat.nvoss.demo.altostrat.com."

# The `artifact_repository_id` and `(shared_)cluster_id` are outputs of the shared
# terraform environment, e.g.:
# `terraform -chdir=environments/shared output`
# Alternatively they can be deduced based on your project id and region!
artifact_repository_id = "projects/nvoss-dogcat-chapter02-shared/locations/europe-west3/repositories/images"
shared_cluster_id      = "projects/nvoss-dogcat-chapter02-shared/locations/europe-west3/clusters/cluster-shared"

# For this cluster an instantiation of apps-of-apps is used, so let's specify
# our fork of the applications repository.
argo_cd_applications_repo_url = "git@github.com:NucleusEngineering/dogcat-applications.git"
argo_cd_sync_policy_automated = true

# Cert-manager will use let's encrypt and to self-register we need an email as well
letsencrypt_email    = "nvoss@google.com"
cert_manager_version = "v1.11.0" # chart-version

# Versions of the components installed to the cluster
external_dns_version            = "v6.14.0" # chart-version
kyverno_version                 = "v2.7.0"  # chart-version
crossplane_version              = "v1.11.1"
crossplane_provider_gcp_version = "v0.28.0"

# Will set up per team resources, such as namespaces, policies and Crossplane-providers
teams = ["dogcat"]
