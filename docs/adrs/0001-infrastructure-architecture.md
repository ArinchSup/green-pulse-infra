# ADR 0001: Split Terraform into Persistent and Ephemeral Stacks

* **Status:** Accepted
* **Date:** 2026-07-26

## Context
Running an always-on EKS cluster costs approximately **$190–$215/month**, as we have limited budget. We can't let it always on.

However, standard `terraform destroy` is all-or-nothing within a single state file. Destroying the stack deletes multi-gigabyte AI container images stored in ECR, forcing long rebuilds and pushing multi-GB image layers that waste **20–40 minutes of wall-clock time** every time the environment is recreated.

## Decision
We will divide our Terraform infrastructure into two separate stacks:
1. `persistent/`: Holds long-lived resources (ECR, storage).
2. `ephemeral/`: Holds compute and networking (EKS clusters, load balancers) that can be torn down on demand.
* **Rationale:** AI Docker images are multi-gigabyte files that take significant CPU and bandwidth to rebuild/push. Destroying `ephemeral/` on Fridays saves compute costs while keeping built containers safe in `persistent/` for quick Monday stand-ups.

## Consequences
* **Cost Reduction:** Teardown discipline reduces overall monthly compute costs from **~$190–$215/month** down to **~$100–$130/month**.
* **Storage Trade-off:** We have to pay continuous storage fee (~$0.10/GB/month) for ECR images.
* **Cross-Stack Complexity:** Resources in `ephemeral/` cannot directly reference objects in `persistent/`. We must explicitly manage cross-stack dependencies using `terraform_remote_state` data sources or passed variables.