# Stop execution immediately if any command fails
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Load secret variables from your uncommitted local file (dot-sourced)
. .\scripts\secrets.local.ps1
#####################################################################################################


# Spin up ephemeral infrastructure
Set-Location .\ephemeral
terraform apply -auto-approve
if ($LASTEXITCODE -ne 0) { throw "terraform apply failed" }
Set-Location ..
#####################################################################################################


# Extract dynamic output parameters from Terraform
Write-Host "Extracting cluster parameters from Terraform..." -ForegroundColor Cyan
$clusterName = terraform -chdir=ephemeral output -raw cluster_name
$vpcId       = terraform -chdir=ephemeral output -raw vpc_id
#####################################################################################################


# Connect kubectl to the new cluster dynamically
aws eks update-kubeconfig --name $clusterName --region ap-southeast-1
if ($LASTEXITCODE -ne 0) { throw "Failed to update kubeconfig" }
#####################################################################################################


# Wait for EC2 worker nodes to fully boot up and register as Ready 
Write-Host "Waiting for cluster worker nodes to become Ready..." -ForegroundColor Cyan
kubectl wait --for=condition=Ready nodes --all --timeout=300s
if ($LASTEXITCODE -ne 0) { throw "nodes never became Ready" }
#####################################################################################################
#replace as the ackend done and the key already up in SSM

# Idempotently apply backend secrets dont use anymore the argoCD steal the job
#kubectl create secret generic backend-secrets `
#  --from-literal=SUPABASE_URL=$env:SUPABASE_URL `
#  --from-literal=SUPABASE_KEY=$env:SUPABASE_KEY `
#  --dry-run=client -o yaml | kubectl apply -f -
#if ($LASTEXITCODE -ne 0) { throw "Failed to apply backend secrets" }

# Idempotently apply AI service secrets 
#kubectl create secret generic ai-service-secrets `
#  --from-literal=FINNHUB_API_KEY=$env:FINNHUB_API_KEY `
#  --from-literal=ANTHROPIC_API_KEY=$env:ANTHROPIC_API_KEY `
#  --dry-run=client -o yaml | kubectl apply -f -
#if ($LASTEXITCODE -ne 0) { throw "Failed to apply AI service secrets" }
#####################################################################################################


# Helm: Add repository safely & Update
Write-Host "Updating Helm repositories..." -ForegroundColor Cyan
helm repo add eks https://aws.github.io/eks-charts --force-update
helm repo add nvdp https://nvidia.github.io/k8s-device-plugin --force-update
helm repo update
if ($LASTEXITCODE -ne 0) { throw "Helm repo update failed" }

# Helm: Install/Upgrade AWS Load Balancer Controller using dynamic inputs
Write-Host "Installing AWS Load Balancer Controller via Helm..." -ForegroundColor Cyan
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller `
  --version 3.6.0 `
  --namespace kube-system `
  --set clusterName=$clusterName `
  --set serviceAccount.create=true `
  --set serviceAccount.name=aws-load-balancer-controller `
  --set region=ap-southeast-1 `
  --set vpcId=$vpcId
if ($LASTEXITCODE -ne 0) { throw "AWS Load Balancer Controller installation failed" }

# Helm: Install/Upgrade NVIDIA Device Plugin
Write-Host "Installing NVIDIA Device Plugin via Helm..." -ForegroundColor Cyan
helm upgrade --install nvidia-device-plugin nvdp/nvidia-device-plugin `
  --version 0.20.1 `
  --namespace kube-system
if ($LASTEXITCODE -ne 0) { throw "NVIDIA Device Plugin installation failed" }


#####################################################################################################



# Wait for the controller Pod to be Available before applying Ingress rules
Write-Host "Waiting for AWS Load Balancer Controller deployment..." -ForegroundColor Cyan
kubectl wait --for=condition=Available deployment/aws-load-balancer-controller -n kube-system --timeout=300s
if ($LASTEXITCODE -ne 0) { throw "LB controller never became Available" }

#####################################################################################################
# Helm: Install Karpenter
$queueName = terraform -chdir=ephemeral output -raw karpenter_queue_name

helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter `
  --version 1.13.0 `
  --namespace kube-system `
  --set "settings.clusterName=$clusterName" `
  --set "settings.interruptionQueue=$queueName"
if ($LASTEXITCODE -ne 0) { throw "Karpenter install failed" }

kubectl wait --for=condition=Available deployment/karpenter -n kube-system --timeout=300s
kubectl wait --for condition=established --timeout=60s crd/nodepools.karpenter.sh
kubectl wait --for condition=established --timeout=60s crd/ec2nodeclasses.karpenter.k8s.aws
if ($LASTEXITCODE -ne 0) { throw "Karpenter never became Available" }

kubectl apply -f karpenter/
if ($LASTEXITCODE -ne 0) { throw "Karpenter NodePool apply failed" }

# Helm: Add prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update
helm repo update

helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack `
  --version 92.2.0 `
  --namespace monitoring `
  --create-namespace `
  --values monitoring/values.yaml `
  --set grafana.adminPassword=$env:GRAFANA_ADMIN_PASSWORD
if ($LASTEXITCODE -ne 0) { throw "monitoring install failed" }

# ESO
helm repo add external-secrets https://charts.external-secrets.io --force-update
helm upgrade --install external-secrets external-secrets/external-secrets `
  --version 2.12.0 `
  --namespace external-secrets --create-namespace
if ($LASTEXITCODE -ne 0) { throw "ESO install failed" }

kubectl wait --for=condition=Available deployment/external-secrets -n external-secrets --timeout=300s

# ArgoCD
helm repo add argo https://argoproj.github.io/argo-helm --force-update
helm upgrade --install argocd argo/argo-cd `
  --version 10.10.1 `
  --namespace argocd --create-namespace `
  --set configs.params."server\.insecure"=true
if ($LASTEXITCODE -ne 0) { throw "ArgoCD install failed" }

kubectl wait --for=condition=Available deployment/argocd-server -n argocd --timeout=300s
if ($LASTEXITCODE -ne 0) { throw "ArgoCD never became Available" }

kubectl create secret generic argocd-repo-green-pulse-infra `
  --namespace argocd `
  --from-literal=type=git `
  --from-literal=url=git@github.com:ArinchSup/green-pulse-infra.git `
  --from-file=sshPrivateKey=$env:ARGOCD_DEPLOY_KEY_PATH `
  --dry-run=client -o yaml | kubectl apply -f -
if ($LASTEXITCODE -ne 0) { throw "ArgoCD repo secret failed" }

kubectl label secret argocd-repo-green-pulse-infra -n argocd argocd.argoproj.io/secret-type=repository --overwrite

#kubectl apply -f gitops/apps/
kubectl apply -f gitops/root-app.yaml
if ($LASTEXITCODE -ne 0) { throw "ArgoCD Application apply failed" }

# Verify deployment status
kubectl get pods