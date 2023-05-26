# The project you created: "${PROJECT_BASENAME}-shared":
project = "nvoss-dogcat-ch02-shared"
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

# Crossplane is setup by terraform and compositions using terraform are set up
crossplane_version                    = "v1.12.1" # chart-version
crossplane_provider_terraform_version = "v0.7.0"

