resource "random_password" "tekton_trigger_secret" {
  length  = 64
  special = true
}

module "tekton_triggers" {
  # We intentionally do not use `kubernetes_manifest` to as it will not
  # successfully plan until Tekton is installed.
  # This can be avoided by using tools such as terragrunt or terramate
  # in a non-demo setup.
  source = "../../modules//helm-manifests"

  name      = "tekton-triggers"
  namespace = "tekton"
  manifests = <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: tekton-trigger-secret
type: Opaque
stringData:
  shared-secret: "${random_password.tekton_trigger_secret.result}"
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tekton-triggers
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: tekton-triggers-eventlistener-binding
subjects:
  - kind: ServiceAccount
    name: tekton-triggers
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: tekton-triggers-eventlistener-roles
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: tekton-triggers-eventlistener-clusterbinding
subjects:
  - kind: ServiceAccount
    name: tekton-triggers
    namespace: tekton
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: tekton-triggers-eventlistener-clusterroles
---
apiVersion: triggers.tekton.dev/v1beta1
kind: EventListener
metadata:
  name: github-listener
spec:
  serviceAccountName: tekton-triggers
  triggers:
    - name: github-listener
      interceptors:
        - ref:
            name: "github"
          params:
            - name: "secretRef"
              value:
                secretName: tekton-trigger-secret
                secretKey: shared-secret
            - name: "eventTypes"
              value: [ "push" ]
        - ref:
            name: "cel"
          params:
          - name: "overlays"
            value:
            - key: image_tag
              expression: "body.ref.startsWith('refs/tags/') ? body.ref.split('/')[2] : body.head_commit.id"
            - key: chart_version
              expression: "body.ref.startsWith('refs/tags/') ? body.ref.split('/')[2] : '0.0.0-dev.'+body.created_at.replace(':', '').replace(' ', '')+'.'+body.head_commit.id"
      bindings:
        - ref: github-binding
      template:
        ref: github-template
---
apiVersion: triggers.tekton.dev/v1beta1
kind: TriggerBinding
metadata:
  name: github-binding
spec:
  params:
    - name: repoName
      value: $(body.repository.name)
    - name: repoRevision
      value: $(body.head_commit.id)
    - name: repoURL
      value: ${var.git_base_url}/$(body.repository.name).git
    - name: image
      value: ${var.image_base}/$(body.repository.name):$(extensions.image_tag)
    - name: chartVersion
      value: $(extensions.chart_version)
---
apiVersion: triggers.tekton.dev/v1beta1
kind: TriggerTemplate
metadata:
  name: github-template
spec:
  params:
    - name: repoName
    - name: repoRevision
    - name: repoURL
    - name: image
    - name: chartVersion
  resourcetemplates:
    - apiVersion: tekton.dev/v1beta1
      kind: PipelineRun
      metadata:
        generateName: $(tt.params.repoName)-run-
      spec:
        serviceAccountName: tekton
        pipelineRef:
          name: $(tt.params.repoName)
        params:
          - name: repoRevision
            value: $(tt.params.repoRevision)
          - name: repoURL
            value: $(tt.params.repoURL)
          - name: image
            value: $(tt.params.image)
          - name: chartVersion
            value: $(tt.params.chartVersion)
        podTemplate:
          securityContext:
            fsGroup: 65532
          nodeSelector:
            cloud.google.com/gke-spot: "true"
        workspaces:
        - name: shared-data
          volumeClaimTemplate:
            spec:
              accessModes:
              - ReadWriteOnce
              resources:
                requests:
                  storage: 4Gi
EOF
}

resource "kubernetes_ingress_v1" "tekton_trigger" {
  metadata {
    name      = "tekton-trigger"
    namespace = "tekton"
    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt"
    }
  }

  spec {
    rule {
      host = var.trigger_domain
      http {
        path {
          path = "/*"
          backend {
            service {
              name = "el-github-listener"
              port {
                number = 8080
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = [var.trigger_domain]
      secret_name = "tekton-trigger-tls"
    }
  }

  depends_on = [module.tekton_triggers]
}
