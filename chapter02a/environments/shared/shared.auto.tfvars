# The project you created: "${PROJECT_BASENAME}-shared":
project = "nvoss-dogcat-chapter02-shared"
# The region you are working in "${REGION}":
region = "europe-west3"

# The cluster will also manage a DNS-zone, so a pre-existing DNS-zone managed
# by Google Cloud is required (as described in the prerequisites).
# The project-name, zone-name and desired fqdn for dedidcated zone are required:
dns_project        = "nvoss-demo-dns"
dns_zone_name      = "nvoss-demo"
dns_dedicated_fqdn = "shared.dogcat.nvoss.demo.altostrat.com."

# We protect our platform-services with IAP, so specify a fitting
# trusted domain and support email for the OAuth-Client.
iap_access_domain = "nvoss.altostrat.com"
iap_support_email = "admin@nvoss.altostrat.com"

# Cert-Manager will use let's encrypt and to self-register we need an email as well
letsencrypt_email    = "nvoss@google.com"
cert_manager_version = "v1.11.0" # chart-version

# We use external-dns to setup DNS records for our Ingress resources
external_dns_version = "v6.14.0" # chart-version

# TODO
chartmuseum_version = "v3.9.3" # chart-version

# ArgoCD versions, domain and which repository is used to roll out applications
argo_cd_version               = "v5.23.5" # chart-version
argo_cd_image_updater_version = "v0.8.4"  # chart-version
argo_cd_domain                = "argocd.shared.dogcat.nvoss.demo.altostrat.com"
# For public repositories use:
# https://github.com/NucleusEngineering/dogcat-applications.git
# For a private repository (make sure credentials are available, check README appendix):
# git@github.com:NucleusEngineering/dogcat-applications.git
argo_cd_applications_repo_url = "git@github.com:NucleusEngineering/dogcat-applications.git"

# Tekton versions and domain
tekton_pipeline_version     = "v0.45.0"
tekton_triggers_version     = "v0.22.2"
tekton_chains_version       = "v0.14.0"
tekton_dashboard_version    = "v0.33.0"
tekton_dashboard_domain     = "tekton.shared.dogcat.nvoss.demo.altostrat.com"
tekton_trigger_git_base_url = "git@github.com:NucleusEngineering"

