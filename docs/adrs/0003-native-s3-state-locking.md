# ADR 0003: Native S3 State Locking

* **Status:** Accepted
* **Date:** 2026-07-26

## Context
Traditionally, AWS setups require DynamoDB table. That adds extra complexity and IAM Overhead.

## Decision
We will use S3's native state locking functionality provided by modern S3 backend rather than DynamoDB table.
* **Rationale:** Removes the need to provision, configure, and monitor a DynamoDB table.

## Consequences
* If S3 native locking ever proves insufficient for complex concurrency needs, this decision can be independently superseded with a DynamoDB implementation without impacting ADR-0001 or ADR-0002.
* **Strict Version Floor (Constraint):** Native S3 state locking strictly requires **Terraform 1.10**. Every team member's local workstation and any automated CI/CD runners must enforce this toolchain version floor; running `terraform init` on older CLI versions will hard-fail.