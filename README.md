# green-pulse-infra

Infrastructure for **Green Pulse**, an AI-powered quantitative stock assistant.
Production-grade Amazon EKS on AWS, built to be destroyed when idle and rebuilt
from code on demand.

## Highlights

- **Rebuilds from nothing with one script.** `scripts/bootstrap.ps1` brings the
  whole platform up in about 25 minutes, and `scripts/teardown.ps1` removes it.
  Data, images and configuration all live outside the cluster, so it is destroyed
  whenever it isn't in use.
- **No long-lived AWS credentials in the cluster or in CI.** Pods get short-lived
  AWS credentials through EKS Pod Identity, and CI authenticates to AWS through
  GitHub OIDC.
- **GitOps with Argo CD.** The cluster continuously matches what's in Git and
  reverts any change made by hand.
- **Secrets never touch Git.** They're stored in AWS SSM Parameter Store and
  copied into the cluster by External Secrets Operator.
- **GPU on demand.** Karpenter launches GPU nodes only when a GPU workload needs
  one (spot first, with on-demand fallback) and removes them when idle. This is
  the main cost saving, at the price of a cold start.
- **Security gates in CI.** Gitleaks and Checkov scan this repository. Trivy scans
  every application image before it's pushed, and has already blocked a build
  containing 17 known vulnerabilities.

## Architecture

Two Terraform stacks with separate state:

- **persistent** — never destroyed: the container registry (ECR), the
  model-weights bucket and the CI identity.
- **ephemeral** — destroyed freely: the network and the EKS cluster
  (Kubernetes 1.36) with its add-ons.

The VPC spans two availability zones. Worker nodes run in private subnets; only
the Application Load Balancer is public, and a single NAT gateway handles
outbound traffic as a deliberate cost trade-off. The backend reads from an
external Postgres database (Supabase), so tearing down the cluster never touches
application data. The application code lives in a separate, private repository.

## Status

- **Scope:** a university senior project — production-grade infrastructure on a
  student budget.
- **Application:** a backend prototype has run end to end, through the load
  balancer to the database and back. The production backend is in progress; the
  frontend isn't built yet.
- **Networking:** HTTP only, with no domain or TLS yet.
- **CI/CD:** deployment through Argo CD (GitOps). This repository's CI runs
  Gitleaks and Checkov. The application's CI scans images with Trivy and pushes
  them to ECR using GitHub OIDC.

## Repository layout

| Path | Purpose |
|---|---|
| `persistent/` | Terraform stack that is never destroyed |
| `ephemeral/` | Terraform stack that is destroyed and rebuilt freely |
| `k8s/` | Kubernetes manifests, deployed by Argo CD |
| `gitops/` | Argo CD applications (app-of-apps) |
| `karpenter/` | GPU node provisioning rules |
| `monitoring/` | Prometheus and Grafana settings |
| `scripts/` | Bring-up, teardown and cleanup verification |
| `tests/` | Manual GPU smoke tests |
| `.github/workflows/` | CI scans |
| `docs/APP-CONTRACT.md` | Contract between the platform and the application |
| `docs/adrs/` | Architecture Decision Records |

## Developer security setup (one time)

To prevent accidental leaks of API keys or secrets, this repository uses
**Gitleaks** with shared pre-commit hooks.

### 1. Install Gitleaks

* **Mac (Homebrew):** `brew install gitleaks`
* **Windows (Winget):** `winget install gitleaks`
* **Linux:** `sudo snap install gitleaks`

### 2. Enable the shared Git hooks

After cloning, run this **once**:

```bash
git config core.hooksPath .githooks
```

## Running it

### Prerequisites

1. AWS CLI v2, Terraform ≥ 1.10, kubectl and Helm, plus an AWS profile with
   administrator access.
2. A read-only GitHub deploy key, so Argo CD can read this repository.
3. Application secrets stored once in SSM Parameter Store, under
   `/green-pulse/<service>/<KEY>` — for example `/green-pulse/backend/DATABASE_URL`.
4. A local, git-ignored file `scripts/secrets.local.ps1` containing:

```powershell
$env:GRAFANA_ADMIN_PASSWORD = "..."
$env:ARGOCD_DEPLOY_KEY_PATH = "C:\path\to\argocd-deploy-key"
```

Run the scripts from the repository root.

### Bring up

```powershell
.\scripts\bootstrap.ps1
```

### Tear down

```powershell
.\scripts\teardown.ps1
.\scripts\verify-clean.ps1
```

`verify-clean.ps1` checks AWS for anything still billing after teardown.

## Cost

Estimated from list prices: about $0.30 per hour for the cluster — roughly
$190–215 a month if left running all the time, versus about $15–30 a month in
practice with teardown when idle. The main costs are the EKS control plane, the
general node and the NAT gateway. GPU nodes are billed separately, and only while
a GPU workload is running.

## Lessons learned

- Kubernetes controllers create AWS resources that Terraform never sees: load
  balancers, security groups, target groups, autoscaler nodes and storage
  volumes. Teardown therefore follows a strict order, and a script verifies that
  nothing was left behind.
- Argo CD's self-healing undoes teardown steps unless it's switched off first.
- EKS bills six times more once a Kubernetes version leaves standard support, and
  moves clusters there automatically. An explicit upgrade policy prevents it.
- An image built by hand, outside CI, turned out to contain vulnerabilities the
  CI gate would have blocked. Only CI-built images get deployed now.

## Design decisions

- [ADR-0001](docs/adrs/0001-split-terraform-state.md) — persistent vs. ephemeral stacks
- [ADR-0002](docs/adrs/0002-standalone-terraform-backend-state-bucket.md) — standalone state bucket
- [ADR-0003](docs/adrs/0003-native-s3-state-locking.md) — native S3 state locking
- [ADR-0004](docs/adrs/0004-declare-eks-core-addons-explicitly.md) — explicit EKS core add-ons
- [ADR-0005](docs/adrs/0005-kubernetes-version-policy.md) — Kubernetes version and support policy
- [ADR-0006](docs/adrs/0006-pod-identity-over-IRSA.md) — Pod Identity over IRSA