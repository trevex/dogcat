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
letsencrypt_email = "nvoss@google.com"

tekton_pipeline_version       = "v0.45.0"
tekton_triggers_version       = "v0.22.2"
tekton_chains_version         = "v0.14.0"
tekton_dashboard_version      = "v0.33.0"
tekton_dashboard_domain       = "tekton.shared.dogcat.nvoss.demo.altostrat.com"
external_dns_version          = "v6.14.0" # chart-version
cert_manager_version          = "v1.11.0" # chart-version
argo_cd_version               = "v5.23.5" # chart-version
argo_cd_image_updater_version = "v0.8.4"  # chart-version
argo_cd_domain                = "argocd.shared.dogcat.nvoss.demo.altostrat.com"
argo_cd_applications_repo_url = "https://github.com/trevex/test-applications.git"
