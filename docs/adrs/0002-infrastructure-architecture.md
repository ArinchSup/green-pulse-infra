# ADR 0002: Standalone Terraform Backend State Bucket

* **Status:** Accepted
* **Date:** 2026-07-26

## Context
If this backend bucket is defined inside either `persistent/` or `ephemeral/`, destroying that stack risks deleting the state file itself.

## Decision
We will provision the backend S3 bucket completely outside both `persistent/` and `ephemeral/`.
* **Rationale:** Deleting `persistent/` or `ephemeral/` will never accidentally destroy the state historical record or lock management files.

## Consequences
* The S3 state bucket must be created manually or bootstrap script as a pre-requisite step before running `terraform init`.