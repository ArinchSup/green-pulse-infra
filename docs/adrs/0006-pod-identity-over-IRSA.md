# ADR 0065: Pod identity instead of IRSA

* **Status:** Accepted
* **Date:** 2026-08-16

## Context
We decide to use ephemeral stacks in this work and if we use IRSA, every new cluster will receive unique  OIDC URL which later will break persistent IAM role in every rebuild. However, for Pod identity, they use universal trust that doesn't need OIDC URL so we can create or reuild EKS cluster as much as we want.

## Decision
We adopt EKS Pod Identity across all Kubernetes ServiceAccounts requiring AWS IAM access—including the AWS Load Balancer Controller, S3 model weight access
* **Rationale:** for persistent it need some id to link and IRSA has the unique one which will break if they do not match 

## Consequences
* We cn rebuild the stack and cluster as many time as we want and the stack wont break.
* Depends on the eks-pod-identity-agent addon running — another moving part
* if we will integrate some services like fargate which is not support the pod identity, the IRASA still need