$ErrorActionPreference = "Stop"

# 1. Disarm GitOps first — selfHeal would recreate anything we delete
kubectl delete application --all -n argocd --ignore-not-found
kubectl delete namespace monitoring --ignore-not-found --timeout=180s

# 2. Ingress → ALB
kubectl delete ingress --all --all-namespaces --ignore-not-found
Write-Host "Waiting for ALB to be deleted..." -ForegroundColor Cyan
Start-Sleep -Seconds 90

# 3. Karpenter nodes
kubectl delete nodepool --all --ignore-not-found
kubectl delete nodeclaim --all --ignore-not-found --timeout=300s

# 4. Terraform-managed infrastructure
Set-Location .\ephemeral
terraform destroy -auto-approve
if ($LASTEXITCODE -ne 0) { throw "terraform destroy failed" }
Set-Location ..