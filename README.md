# green-pulse-infra

Infrastructure for Green Pulse — a stock analysis platform with AI-powered
news analysis. Production-grade EKS on AWS, built to be destroyed and
rebuilt on demand.

## Architecture
The main core concept of this architecture is to be able to destroy the instance and rebuild in ~25 minutes. Thus, we use the ephemeral and persistent stack which for ephemeral we can destroy it when we dont use. The infrastructure has 2 Azs, private worker node, single NAT, single ALB ingress,GPU nodes (g4dn/g5/g6 .xlarge, spot-first with on-demand fallback) are provisioned on demand by Karpenter when an inference pod is scheduled, and removed automatically once idle.

## Status
- Scope: This project is built for the university senior project, thus the goal is to build the production grade infrastructure while in the budget of students.
- Status: the place holder images or the production is still missing out as the production itself is in the process of reworking, and the CI/CD is still not done properly as now we are using the shell scripts and manualy start the infrastructure, and the HTTP only with no domain yet, as it will cost a lot and we will get ceritificte for HTTPS and the domain name as the product are done and it can pair with the infrastructure properly.

## Repository layout
| Path | Purpose |
|---|---|
| `persistent/` | The stack the will never destroyed |
| `ephemeral/` | The stack that can be destroyed and revuild again |
| `k8s/` | Kubernetes config |
| `karpenter/` | Node provisioner |
| `monitoring/` | Prometheus/Grafana |
| `scripts/` | Use for running up or down the infrastructure |
| `tests/` | test inference subject |
| `docs/adr/` | decisions of architecture |

## Developer Security Setup (One-Time Setup)

To prevent accidental leaks of API keys or secrets, this repository uses **Gitleaks** with shared pre-commit hooks.

### 1. Install Gitleaks
Make sure `gitleaks` is installed on your system:
* **Mac (Homebrew):** `brew install gitleaks`
* **Windows (Winget):** `winget install gitleaks`
* **Linux:** `sudo snap install gitleaks`

### 2. Enable Shared Git Hooks
After cloning the repository, run this command in your terminal **once** to enable local security checks:

```bash
git config core.hooksPath .githooks
```
## Running it
### Prerequisites
1. AWS CLI v2, Terraform ≥1.10, kubectl, Helm, an AWS profile with admin, Docker Desktop for ECR pushes.
2. Updates the secrets: in scripts folders add the secrets.local.ps1 then add
```
$env:SUPABASE_URL      = "..."
$env:SUPABASE_KEY      = "..."
$env:FINNHUB_API_KEY   = "..."
$env:ANTHROPIC_API_KEY = "..."
$env:GRAFANA_ADMIN_PASSWORD = "..."
```

### Bring up
```bash
./scripts/bootstrap.ps1
```

### Tear down
```bash
./scripts/teardown.ps1
./scripts/verify-clean.ps1
```

## Cost
The cost is around ~$0.30/hr, ~$190-215 always-on, ~$15-30/month at low usage.
Most of the price came from the GPU nodes run only while inference is active, NAT gateway (single), single ingress.

## Design decisions
- [ADR-0001](docs/adrs/0001-split-terraform-state.md) — persistent vs ephemeral stacks
- [ADR-0002](docs/adrs/0002-standalone-terraform-backend-state-bucket.md) — Standalone backend bucket
- [ADR-0003](docs/adrs/0003-native-s3-state-locking.md) — Native S3 state locking
- [ADR-0004](docs/adrs/0004-declare-eks-core-addons-explicitly.md) — EKS core add-ons
- [ADR-0005](docs/adrs/0005-kubernetes-version-policy.md) — pinning standard support
- [ADR-0006](docs/adr/0006-pod-identity-over-IRSA.md) — Pod identity over IRSA