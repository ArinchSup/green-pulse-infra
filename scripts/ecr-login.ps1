$ErrorActionPreference = "Stop"

$accountId = "465853822810"
$region    = "ap-southeast-1"
$registry  = "$accountId.dkr.ecr.$region.amazonaws.com"

docker info *> $null
if ($LASTEXITCODE -ne 0) { throw "Docker Desktop is not running" }

# NOTE: --password-stdin is the documented form, but PowerShell 5.1 corrupts
# the token through the pipe, so docker stores nothing and pushes fail with
# "no basic auth credentials". Passing via variable is the workaround.
$pw = aws ecr get-login-password --region $region
if ($LASTEXITCODE -ne 0) { throw "Failed to get ECR token" }

docker login --username AWS --password $pw $registry
if ($LASTEXITCODE -ne 0) { throw "docker login failed" }

Write-Host "Logged in to $registry (token valid 12h)" -ForegroundColor Green