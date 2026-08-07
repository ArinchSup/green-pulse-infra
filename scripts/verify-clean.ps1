$region  = "ap-southeast-1"
$account = "465853822810"

Write-Host "`n=== SHOULD BE EMPTY ===" -ForegroundColor Yellow

Write-Host "`nEKS clusters:" -ForegroundColor Cyan
aws eks list-clusters --region $region --query "clusters" --output text

Write-Host "NAT gateways:" -ForegroundColor Cyan
aws ec2 describe-nat-gateways --region $region --filter "Name=state,Values=available" --query "NatGateways[].NatGatewayId" --output text

Write-Host "Elastic IPs:" -ForegroundColor Cyan
aws ec2 describe-addresses --region $region --query "Addresses[].PublicIp" --output text

Write-Host "Load balancers:" -ForegroundColor Cyan
aws elbv2 describe-load-balancers --region $region --query "LoadBalancers[].LoadBalancerName" --output text

Write-Host "Target groups:" -ForegroundColor Cyan
aws elbv2 describe-target-groups --region $region --query "TargetGroups[].TargetGroupName" --output text

Write-Host "green-pulse VPC:" -ForegroundColor Cyan
aws ec2 describe-vpcs --region $region --filters "Name=tag:Name,Values=green-pulse-vpc" --query "Vpcs[].VpcId" --output text

Write-Host "`n=== SHOULD STILL EXIST ===" -ForegroundColor Yellow

Write-Host "`nECR repos:" -ForegroundColor Cyan
aws ecr describe-repositories --region $region --query "repositories[].repositoryName" --output text

Write-Host "State files:" -ForegroundColor Cyan
aws s3 ls "s3://green-pulse-tfstate-$account/" --recursive