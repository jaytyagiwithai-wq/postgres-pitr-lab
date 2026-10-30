# PostgreSQL PITR recovery lab

A hands-on PostgreSQL 16 point-in-time recovery (PITR) drill using WAL-G, S3 WAL archiving, Docker Compose, and Terraform. It simulates an accidental table-wide delete, restores a base backup, replays WAL only through a named restore point, and verifies the recovered rows.

## What it demonstrates

- PostgreSQL base backups and continuous WAL archiving with WAL-G
- A named restore point and a time-based recovery target
- A least-privilege Terraform IAM policy for the lab's S3 bucket
- Recovery data isolation in a separate Docker volume
- A recorded incident timeline and a verified recovery result

## Recovery result

The local recovery volume was copied into an isolated, network-disabled container and queried read-only. The recovered `lab.orders` table contained all six expected rows (`LAB-001` through `LAB-006`); the later committed delete was not replayed. See [docs/incident-record.md](docs/incident-record.md) for the inputs and timeline.

## Components

- `compose.yaml` runs the PostgreSQL primary and a separately profiled recovery instance. Both publish ports on loopback only.
- `postgres/` configures PostgreSQL 16 and WAL-G.
- `scripts/prepare-recovery.sh` fetches the selected base backup and configures PostgreSQL's recovery target.
- `sql/` contains the synthetic seed data, a post-backup insert, and the simulated destructive statement.
- `infra/terraform/` provisions the lab's S3 bucket and scoped IAM permissions.

## Prerequisites

Docker Compose, Terraform, and an AWS account with permission to create the lab's S3 bucket and IAM resources. The AWS resources can incur charges. Use a dedicated lab account/role and remove the resources after the exercise. Terraform and AWS were not run as part of publishing this repository.

Never commit real AWS credentials, `.env`, Terraform state, or saved plan files. `.env.example` contains only a local placeholder; export temporary AWS credentials and the lab's S3 prefix in your shell before using Compose. The Compose configuration requires temporary AWS session credentials for the archival workflow.

## Repository safety

The `.gitignore` excludes local credentials, database/recovery data, Terraform state, plans, and variable files. Only Terraform source and the provider lock file belong in Git.

## Scope

This is an educational recovery drill, not a production backup service. It does not provide a production-tested retention policy, monitoring/alerting, automated orchestration, or a guaranteed recovery time objective. Validate backup integrity and recovery procedures for your own environment before relying on them.
