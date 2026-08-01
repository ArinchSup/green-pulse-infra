# ADR 0004: declare EKS core addons

* **Status:** Accepted
* **Date:** 2026-08-1

## Context
Creating the EKS but found out there no resources found across namespaces. Normally cluters will run aws-node, kube-proxy, and coredns. However, nothing is running which mean no CNI. 

## Decision
Add the addons in the eks module
* **Rationale:** We will let it all download beore the computing with "before_compute = true" so the CNI will download before node groups are created

## Consequences
* The cni will download beforehand so the eks can now apply.