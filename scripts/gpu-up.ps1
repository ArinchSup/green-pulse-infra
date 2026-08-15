$ErrorActionPreference = "Stop"
$cluster = "green-pulse-cluster"
$region  = "ap-southeast-1"

$ng = aws eks list-nodegroups --cluster-name $cluster --region $region --query "nodegroups[?starts_with(@,'gpu')]|[0]" --output text
if (-not $ng -or $ng -eq "None") { throw "no gpu nodegroup found" }

aws eks update-nodegroup-config --cluster-name $cluster --nodegroup-name $ng --scaling-config minSize=0,maxSize=1,desiredSize=1 --region $region
Write-Host "Scaling up $ng - takes 3-4 min. Meter running (about USD 0.60/hr)." -ForegroundColor Yellow