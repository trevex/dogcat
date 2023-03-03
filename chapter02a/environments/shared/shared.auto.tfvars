project                       = "nvoss-dogcat-chapter-02-shared"
region                        = "europe-west1"
dns_project                   = "nvoss-demo-dns"
dns_zone_name                 = "nvoss-demo"
dns_dedicated_fqdn            = "shared.dogcat.nvoss.demo.altostrat.com."
iap_access_domain             = "nvoss.altostrat.com"
iap_support_email             = "admin@nvoss.altostrat.com"
letsencrypt_email             = "nvoss@google.com"
tekton_pipeline_version       = "v0.45.0"
tekton_triggers_version       = "v0.22.2"
tekton_dashboard_version      = "v0.33.0"
tekton_dashboard_domain       = "tekton.shared.dogcat.nvoss.demo.altostrat.com"
external_dns_version          = "v6.14.0" # chart-version
cert_manager_version          = "v1.11.0" # chart-version
argo_cd_version               = "v5.23.5" # chart-version
argo_cd_domain                = "argocd.shared.dogcat.nvoss.demo.altostrat.com"
argo_cd_applications_repo_url = "https://github.com/trevex/test-applications.git"
