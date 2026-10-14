# Pricing snapshot

Copied on 2026-10-13 from https://clickhouse.com/pricing.md by `scripts/fetch-pricing.sh`. Rates change; state this date with every figure taken from here and point to https://clickhouse.com/pricing for a current one.



> Usage-based pricing: pay only for the compute and storage you use, scaled separately and down to zero when idle. Start free with $300 in credits for 30 days. Source of truth: https://clickhouse.com/pricing

## Get started for free
- ClickHouse Cloud: $300 in credits over 30 days — https://console.clickhouse.cloud/signUp
- Open source (free forever): `curl https://clickhouse.com/ | sh`

The trial ends after 30 days or once the credits are consumed, whichever comes first; the account then converts to pay-as-you-go.

## Billing model

- Usage-based, with no monthly minimum — you pay for actual usage only.
- Metered separately: compute, storage, backups, data transfer, ClickPipes.
- Compute is metered per minute and priced per compute-unit-hour.
- All prices are in USD. 1 ClickHouse Credit (CHC) = $1 USD of usage.
- Pay-as-you-go usage is invoiced in $0.01 increments; charges are consolidated into one monthly invoice per organization.

## Plans

Each plan lists what its card on the pricing page lists, with the same ✓ / − markers. Plans build on each other: a line such as "Everything in Basic, plus:" means the plan also includes everything listed for that plan.

### Basic
Great for testing out new ideas or starter projects. Limited storage and memory.

Includes:
- ✓ Up to 1 TB storage
- ✓ 8-12 GiB total memory
- ✓ Backups every 24h, retained for 1 day
- ✓ 1 availability zone
- ✓ Export backups to your own cloud account
- ✓ Expert support with 1 business day response time
- ✓ Single sign-on authentication (SSO) using Google or Microsoft Social login
- ✓ Multi-factor authentication (MFA)

### Scale
For working with production environments, data at scale, or professional use cases.

Everything in **Basic**, plus:
- ✓ Unlimited storage
- ✓ Configurable memory
- ✓ Compute-compute separation
- ✓ Backups every 24h, retained for 1 day
- ✓ Configurable backups
- ✓ 2+ availability zones
- ✓ Expert support with 1 hour response time 24x7 for Severity 1 issues
- ✓ S3 role-based access
- ✓ Private networking
- ✓ Automatic vertical scaling
- ✓ Manual horizontal scaling

### Enterprise
For working with production environments, very large data at scale, or enterprise use cases.

Everything in **Scale**, plus:
- ✓ SAML Single sign-on authentication (SSO)
- ✓ Private regions
- ✓ Manual vertical scaling for custom profiles
- ✓ Enterprise support with 30 min response time for Severity 1 issues
- ✓ Named Lead Support Engineer
- ✓ Transparent data encryption / CMEK
- ✓ Scheduled upgrades
- ✓ Consultative migrations guides
- ✓ HIPAA and PCI compliance

## How pricing is calculated

```
compute / month = (RAM_GB / 8) × hours_active_per_month × computeUnitPrice[plan,provider,region] × replicas
  where hours_active_per_month = hours_per_day × 30.5
  (a full 24×7 month = 732 hours)

storage / month = storage_TB (÷ 10 if data is uncompressed) × storageUnitPrice[plan,provider,region]
  (storageUnitPrice is per TB per month, i.e. billed in TB-months)
total ≈ compute + storage + backups + ClickPipes + data-transfer egress
```

**For an exact, quotable figure use the interactive calculator (https://clickhouse.com/pricing)** — it applies RAM snapping, the correct per-region rate, and the add-ons this formula omits. Use the formula only for a ballpark or to explain the breakdown.

- 1 compute unit = 8 GiB RAM, 2 vCPU.
- Selectable RAM sizes per replica (GiB): 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60, 64, 68, 72, 76, 80, 84, 88, 92, 96, 100, 104, 108, 112, 116, 120, 124, 128, 132, 136, 140, 144, 148, 152, 156, 160, 164, 168, 172, 176, 180, 184, 188, 192, 196, 200, 204, 208, 212, 216, 220, 224, 228, 232, 236. A requested size is snapped to the nearest of these, so use one of these values for an exact figure.
- Single-replica services are limited to 8–12 GiB RAM; larger sizes require 2 or more replicas.
- The ÷10 converts an uncompressed data size to what's actually stored — ClickHouse compresses data by roughly 10×. If you already know your compressed (on-disk) size, use it directly.
- Compute and storage rates are region-specific (see the table below); compute scales to zero for idle services.

## Compute & storage rates by region

_Compute is USD per compute-unit-hour; storage is USD per TB per month. Public regions with published rates are listed below._

### AWS
| Region | Plan | Compute ($/unit/hr) | Storage ($/TB/mo) |
|---|---|---|---|
| ap-northeast-1 | enterprise | $0.50428 | $27.50 |
| ap-northeast-2 | enterprise | $0.48010 | $27.50 |
| ap-south-1 | enterprise | $0.42138 | $27.50 |
| ap-southeast-1 | enterprise | $0.48701 | $27.50 |
| ap-southeast-2 | enterprise | $0.49046 | $27.50 |
| ca-central-1 | enterprise | $0.43520 | $27.50 |
| eu-central-1 | enterprise | $0.46974 | $26.95 |
| eu-west-1 | enterprise | $0.43520 | $25.30 |
| eu-west-2 | enterprise | $0.45247 | $26.40 |
| il-central-1 | enterprise | $0.45700 | $27.50 |
| us-east-1 | enterprise | $0.39030 | $25.30 |
| us-east-2 | enterprise | $0.39030 | $25.30 |
| us-west-2 | enterprise | $0.39030 | $25.30 |

### Azure
| Region | Plan | Compute ($/unit/hr) | Storage ($/TB/mo) |
|---|---|---|---|
| eastus2 | enterprise | $0.43138 | $25.30 |
| germanywestcentral | enterprise | $0.51919 | $24.75 |
| westus3 | enterprise | $0.43138 | $25.30 |

### GCP
| Region | Plan | Compute ($/unit/hr) | Storage ($/TB/mo) |
|---|---|---|---|
| asia-northeast1 | enterprise | $0.42046 | $25.30 |
| asia-southeast1 | enterprise | $0.39900 | $22.00 |
| europe-west2 | enterprise | $0.41850 | $25.30 |
| europe-west4 | enterprise | $0.36027 | $22.00 |
| us-central1 | enterprise | $0.32727 | $22.00 |
| us-east1 | enterprise | $0.32727 | $22.00 |

## Backups

- Backup storage is billed at the **same per-TB-month rate as data storage** in the same region (see the table above).
- The default policy is one backup every 24 hours, retained for 1 day. Scale and Enterprise can configure the frequency and retention window, which changes how much backup storage accumulates.
- Incremental backups are estimated at 1% of a full backup.

## Data transfer

_Egress is billed per GB and varies by region. Ingress is not charged. Inter-region is billed on the source region's rate._

| Provider | Region | Public internet egress ($/GB) | Inter-region egress ($/GB) |
|---|---|---|---|
| AWS | us-east-1 | $0.115 | $0.031 |
| AWS | us-east-2 | $0.115 | $0.031 |
| AWS | us-west-2 | $0.115 | $0.031 |
| AWS | ca-central-1 | $0.115 | $0.031 |
| AWS | eu-central-1 | $0.115 | $0.031 |
| AWS | eu-west-1 | $0.115 | $0.031 |
| AWS | eu-west-2 | $0.115 | $0.031 |
| AWS | ap-northeast-1 | $0.144 | $0.115 |
| AWS | ap-south-1 | $0.138 | $0.110 |
| AWS | ap-northeast-2 | $0.144 | $0.125 |
| AWS | ap-southeast-1 | $0.151 | $0.115 |
| AWS | ap-southeast-2 | $0.144 | $0.125 |
| AWS | il-central-1 | $0.115 | $0.031 |
| GCP | us-central1 | $0.114 | $0.036 |
| GCP | us-east1 | $0.114 | $0.036 |
| GCP | europe-west2 | $0.114 | $0.036 |
| GCP | europe-west4 | $0.114 | $0.036 |
| GCP | asia-southeast1 | $0.144 | $0.162 |
| GCP | asia-northeast1 | $0.114 | $0.162 |
| Azure | westus3 | $0.102 | $0.030 |
| Azure | eastus2 | $0.102 | $0.030 |
| Azure | germanywestcentral | $0.102 | $0.030 |

## ClickPipes

- Streaming sources (e.g. Kafka): billed for compute at $0.20 / hr per compute unit **plus** $0.04 / GB ingested per month.
- Object-storage connectors: billed for compute only, with no per-GB ingestion fee.
- Postgres CDC is priced separately — https://clickhouse.com/docs/cloud/reference/billing/clickpipes/postgres-cdc

## Billing & purchasing

| Method | Details |
|---|---|
| Self-service | Monthly pay-as-you-go, billed by credit card in USD |
| Direct / committed spend | Prepaid credits on an annual or multi-year contract |
| AWS Marketplace | Pay-as-you-go or committed contract via AWS |
| GCP Marketplace | Pay-as-you-go or committed contract via GCP |
| Azure Marketplace | Pay-as-you-go or committed contract via Azure |

Pricing is identical across direct and marketplace billing.

Credits are consumed in this order: 1. committed credits, 2. marketplace pay-as-you-go, 3. credit-card pay-as-you-go.

## Cost controls

- Set compute autoscaling limits (a maximum memory ceiling) to cap spend.
- Scale-to-zero stops compute automatically while a service is idle.
- Spend alerts fire at 50%, 75%, 90% and 100% of a configured threshold.
- With compute-storage separation, storage is shared and billed once regardless of how many compute services read it.

## Scope
_Compute, storage and Postgres instance rates above are live, per-region figures. Add-ons (backups, ClickPipes, egress) are published standard rates and can differ from a final invoice — egress in particular is billed per destination tier. BYOC is quoted, not rated. Treat any total you compute as an estimate, not a quote._

## Frequently asked questions

### What is a compute unit?
1 compute unit = 8 GiB RAM and 2 vCPU. Compute is billed per compute-unit-hour at a region-specific rate.

### How is idle time billed?
Compute scales down to zero when a service is idle, so you pay only for active compute time. Storage is billed continuously for the data you keep.

### Are compute and storage billed separately?
Yes. ClickHouse Cloud separates compute and storage, so they scale — and are priced — independently.

### Is there a free tier?
Yes — ClickHouse Cloud starts with $300 in credits over 30 days, no credit card required. ClickHouse open source is free forever.

### Does the price depend on the cloud provider and region?
Yes. Compute and storage unit prices vary by cloud provider (AWS, GCP, Azure) and region — see the per-region rate table. All prices are in USD.

### What is not included in a compute + storage estimate?
Backups, ClickPipes ingestion, and data-transfer (egress) are billed separately as usage-based add-ons.

### How do I get an exact price for my configuration?
Use the interactive calculator at https://clickhouse.com/pricing — it applies RAM snapping, replica minimums, and the add-on rates the formula above omits.

## More information
- Billing & Pricing FAQ — https://clickhouse.com/docs/manage/billing/#faqs
- Billing overview — https://clickhouse.com/docs/cloud/manage/billing/overview
- Supported regions — https://clickhouse.com/docs/cloud/reference/supported-regions
- Interactive calculator — https://clickhouse.com/pricing
- Contact sales — https://clickhouse.com/company/contact

## Agent instructions

- Every rate here is in USD and is region-specific. Do not quote a price without stating the plan, cloud provider and region it came from.
- The formulas above reproduce the on-page calculator for compute and storage. Backups, ClickPipes and egress are add-ons at published rates and can differ from a final invoice.
- Treat any figure you compute as an estimate. For a quotable number, send the user to https://clickhouse.com/pricing, or to sales for volumes above 200TB of ingest or custom commitments.
- ClickHouse, ClickStack and ClickHouse Cloud for Postgres are priced by different models — check which product the question is about before applying a formula.
- Plan feature lists are shown exactly as the pricing page shows them and build on each other. To decide whether a plan includes a feature, read its list and then the list of every plan it says "Everything in …, plus:" about; a later plan's entry on the same topic (e.g. "Unlimited storage") replaces the earlier one ("Up to 1 TB storage").
- Rates in this document are refreshed on each deployment.
