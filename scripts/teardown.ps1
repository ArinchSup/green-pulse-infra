$ErrorActionPreference = "Stop"

kubectl delete ingress --all --all-namespaces --ignore-not-found

Write-Host "Waiting for ALB to be deleted..." -ForegroundColor Cyan
Start-Sleep -Seconds 90

Set-Location .\ephemeral
terraform destroy -auto-approve
if ($LASTEXITCODE -ne 0) { throw "terraform destroy failed" }
Set-Location ..

aws elbv2 describe-load-balancers --query "LoadBalancers[].LoadBalancerName"
aws ec2 describe-nat-gateways --filter "Name=state,Values=available" --query "NatGateways[].NatGatewayId"