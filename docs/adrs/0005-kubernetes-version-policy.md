# ADR 0005: Kubernetes version policy

* **Status:** Accepted
* **Date:** 2026-08-01

## Context
At first, we decide to use eks version 1.33 but it expired July 29 so it ask us to use extended support which will cost 6x more as standard support cost $0.1/hr while extended version cost $0.6/hr. AWS switches you and bills 6x silently and total will ost around ~$73/mo → ~$438/mo.

## Decision
We add upgrade_policy to eks module, so we choose 1.36 instead of 1.35 as the 1.35 will be expired by March 2027 while the 1.36 stndard support to Aug 2027. Thus adding upgrade policy to STANDARD will be guardrail.
* **Rationale:** AWS will auto upgrade at the end-of-standard rather than switching to extended version. 

## Consequences
* when the eks version is expired aws will auto upgraded your version to newer one so the control plan change without asking us. However, this might affect some part of our work as if the newer version might not get supported by ours others tools
* The ephemeral still handly here as we can destroy can change the version and build easily. 