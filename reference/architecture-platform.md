# Platform decisions: where the service runs and how it connects

Decisions of the platform layer that `poc-architecture-design` goes through with the user. Each has the questions that
decide it, how the answer branches, and the official pages. These are product facts that change; they were checked on
clickhouse.com on 2026-10-16. Cite the URLs as they are. When a fact here may have changed (a feature in preview, a
region list), confirm it with the documentation search tool before relying on it.

Rules for this file:

- **Rule**: present each decision as a candidate with its conditions; the user and their ClickHouse contact decide.
- **Rule**: when a feature is available only in some tiers, state that fact and its source. Do not recommend a tier,
  a size or a price, and do not say which tier the PoC needs.
- **Rule**: ClickHouse facts come from these pages and the documentation search tool. Facts on the cloud provider's
  side (setting up a private endpoint in the user's account, regional availability of a provider service, IAM on the
  source) come from the provider's documentation: through its knowledge tool when it is connected (see "Cloud provider
  knowledge tools" below), otherwise by giving the provider's documentation URL.

## Deployment: ClickHouse Cloud or BYOC

- **Questions**: must the data plane run in the user's own cloud account? Does the PoC need ClickPipes, the SQL
  console or autoscaling?
- **Branches**:
  - In BYOC, the control plane runs in ClickHouse's VPC and the data plane in the user's cloud account; AWS, GCP and
    Azure are supported. It is for large deployments and needs a committed contract; access is by request.
  - BYOC needs a region with three availability zones and a Kubernetes cluster that ClickHouse manages (an existing
    cluster is not supported).
  - BYOC does not support ClickPipes, the SQL console, autoscaling or customer-managed encryption keys (listed as
    planned). A PoC that depends on these cannot be run on BYOC as it is today.
  - Otherwise the PoC runs on ClickHouse Cloud.
- **Sources**: https://clickhouse.com/docs/products/cloud/guides/infrastructure/deployment-options/byoc/overview ,
  https://clickhouse.com/docs/products/bring-your-own-cloud/onboarding/standard

## Cloud provider and region

- **Questions**: where are the data sources and the clients (provider and region)? Must the data stay in a country or
  region? Is HIPAA or PCI needed?
- **Branches**:
  - The regions page lists, per provider, which regions are public, private, HIPAA, PCI or BYOC. Private regions are
    offered for Enterprise tier services and do not autoscale or idle; HIPAA is available only for Enterprise tier
    services.
  - Data transfer to the public internet (including other clouds) and to another region of the same provider is
    charged; transfer within a region and over PrivateLink or Private Service Connect is not charged by ClickHouse,
    but the provider's charges apply. A service in the same provider and region as the sources avoids the first two.
- **Sources**: https://clickhouse.com/docs/products/cloud/reference/supported-regions ,
  https://clickhouse.com/docs/products/cloud/reference/billing/network-data-transfer

## Connection path into the service

- **Questions**: may clients connect over the public internet from known addresses, or must traffic stay private?
  Which provider network do the clients run in?
- **Branches**:
  - Public: each service has an IP access list; the default allows any address; only IPv4 is supported. The list
    applies only to public connections. To allow only private traffic, deny all public addresses.
  - Private: AWS PrivateLink, GCP Private Service Connect and Azure Private Link are available in the Scale and
    Enterprise plans. They carry connections from the user's network into ClickHouse Cloud only, not from ClickHouse
    Cloud to the user's network. Private Service Connect needs the consumer in the same region as the service.
    After the endpoint is approved, the service must still allow it (it is not reachable by default).
- **Sources**: https://clickhouse.com/docs/products/cloud/guides/security/connectivity/setting-ip-filters ,
  https://clickhouse.com/docs/products/cloud/guides/security/connectivity/private-networking/aws-privatelink ,
  https://clickhouse.com/docs/products/cloud/guides/security/connectivity/private-networking/gcp-private-service-connect ,
  https://clickhouse.com/docs/products/cloud/guides/security/connectivity/private-networking/azure-privatelink
- **Provider side**: https://docs.aws.amazon.com/vpc/latest/privatelink/what-is-privatelink.html ,
  https://cloud.google.com/vpc/docs/private-service-connect ,
  https://learn.microsoft.com/azure/private-link/private-link-overview

## Connection path from ClickPipes to the sources

- **Questions**: are the sources reachable from the internet? If not, on which provider are they?
- **Branches**:
  - Public sources: allow the ClickPipes egress addresses of the service's region at the source. The addresses are
    listed per region and in `https://api.clickhouse.cloud/static-ips.json`; for some regions, which addresses apply
    depends on when the service was created, so check the page for the service's region. For object storage pipes,
    the page also lists the service's own addresses.
  - Private sources: ClickPipes creates a reverse private endpoint. AWS PrivateLink is supported for Kafka, Postgres,
    MySQL and MongoDB sources; GCP Private Service Connect is supported; Azure Private Link is not (use an SSH
    tunnel).
  - Amazon S3 buckets: the S3 ClickPipe supports public and private buckets and IAM role authentication.
- **Sources**: https://clickhouse.com/docs/integrations/clickpipes/networking ,
  https://clickhouse.com/docs/integrations/clickpipes/networking/aws-privatelink ,
  https://clickhouse.com/docs/integrations/clickpipes/networking/gcp-psc ,
  https://clickhouse.com/docs/integrations/clickpipes/networking/static-ips ,
  https://clickhouse.com/docs/integrations/clickpipes/object-storage/amazon-s3/overview

## Integrations: entry and exit

- **Questions**: where does the data come from (event streams, files in object storage, an operational database)?
  Is the PoC a one-time load, continuous ingest, or both? What reads the results (BI, an application, dbt, notebooks)?
- **Branches** (the ingest pattern itself is decided with `clickhouse-architecture-advisor`; this is where each
  source connects):
  - Event streams: ClickPipes for Kafka (Apache Kafka, Confluent Cloud, Redpanda, Amazon MSK, Google Cloud Managed
    Service for Apache Kafka, Azure Event Hubs, WarpStream) and Kinesis. On ClickHouse Cloud the documentation
    recommends ClickPipes instead of the Kafka table engine.
  - Object storage: ClickPipes for S3, GCS and Azure Blob Storage for continuous loads; the `s3` and `gcs` table
    functions for one-time loads with `INSERT ... SELECT`; the S3Queue table engine. S3 role-based access is
    available in the Scale and Enterprise plans.
  - Databases: ClickPipes for Postgres and MySQL (initial load and change data capture) and MongoDB (public beta).
  - The ClickPipes page lists each connector's lifecycle stage (GA, beta, preview); check it for the source.
  - Exit: the integrations pages list BI and visualization tools, dbt and the language clients, each marked as a
    core, partner or community integration.
- **Sources**: https://clickhouse.com/docs/integrations/clickpipes ,
  https://clickhouse.com/docs/integrations/clickpipes/kafka ,
  https://clickhouse.com/docs/integrations/clickpipes/postgres ,
  https://clickhouse.com/docs/integrations/clickpipes/mysql ,
  https://clickhouse.com/docs/integrations/clickpipes/mongodb ,
  https://clickhouse.com/docs/reference/functions/table-functions/s3 ,
  https://clickhouse.com/docs/reference/engines/table-engines/integrations/s3queue ,
  https://clickhouse.com/docs/integrations/connectors/data-ingestion/kafka/kafka-table-engine ,
  https://clickhouse.com/docs/integrations/connectors/data-visualization ,
  https://clickhouse.com/docs/integrations/connectors/data-ingestion/etl-tools/dbt ,
  https://clickhouse.com/docs/integrations/language-clients

## Authentication and security

- **Questions**: how do people sign in to the console (company identity provider or not)? Must the user manage the
  encryption key? Who needs the audit trail of console actions and of queries?
- **Branches**:
  - Console sign-in: SAML SSO is an Enterprise plan feature. The pricing page lists Google or Microsoft social login
    and multi-factor authentication in the Basic plan.
  - Encryption: services are encrypted with ClickHouse's key by default. Transparent data encryption with a
    customer-managed key is an Enterprise plan feature on AWS and GCP, must be turned on when the service is created,
    and cannot be turned off afterwards; backup export is not supported for such services.
  - Audit: console actions are in the organization's audit log (needs the "View audit logs" permission); database
    sessions and queries are in `system.session_log` and `system.query_log`, kept up to 30 days by default.
  - Database users: create a dedicated user per application with only the grants it needs; passwords need at least
    12 characters.
- **Sources**: https://clickhouse.com/docs/products/cloud/guides/security/cloud-access-management/saml-sso-setup ,
  https://clickhouse.com/pricing ,
  https://clickhouse.com/docs/products/cloud/guides/security/cmek ,
  https://clickhouse.com/docs/products/cloud/guides/security/audit-logging/console-audit-log ,
  https://clickhouse.com/docs/products/cloud/guides/security/audit-logging/database-audit-log ,
  https://clickhouse.com/docs/products/cloud/guides/security/cloud-access-management/manage-database-users

## Separating ingest from queries

- **Questions**: would heavy loads or merges slow the queries the PoC measures? Do different teams need their own
  compute on the same data?
- **Branches**:
  - Compute-compute separation (warehouses) is available in the Scale and Enterprise plans. Services in a warehouse
    share the data, the users and the region; the first service is read-write; a service's type (read-write or
    read-only) is fixed when it is created. Read-only services do no background merges, and refreshable materialized
    views run only on read-write services.
  - With one service, ingest and queries share its compute; the load-test review then reads both together.
- **Sources**: https://clickhouse.com/docs/products/cloud/features/infrastructure/warehouses

## Backup and recovery

- **Questions**: does the PoC need to show a restore, and how long it takes? Must backups go to the user's own bucket
  or another region?
- **Branches**:
  - By default a service has one daily backup kept for 24 hours. Configurable schedules and retention are available
    in the Scale and Enterprise plans.
  - A restore always creates a new service; measure restore time by restoring to a new service.
  - Backups can be exported to the user's own S3, GCS or Azure bucket; cross-region export incurs transfer charges,
    and the SQL `BACKUP` privilege must be requested from support.
- **Sources**: https://clickhouse.com/docs/products/cloud/features/backups/overview ,
  https://clickhouse.com/docs/products/cloud/guides/backups/configurable-backups ,
  https://clickhouse.com/docs/products/cloud/guides/backups/review-and-restore-backups ,
  https://clickhouse.com/docs/products/cloud/guides/backups/bring-your-own-backup/export-backups-to-own-cloud-account

## Tiers

- **Rule**: tiers are set per organization; all services of an organization have the same tier. The tiers page
  describes what each tier includes. Report what a feature's page says about tiers; do not choose one.
- **Sources**: https://clickhouse.com/docs/products/cloud/features/cloud-tiers , https://clickhouse.com/pricing

## Cloud provider knowledge tools

The provider's official documentation server can be added to the agent as an MCP server (optional; see
docs/setup.md). Use it only when its tools are in this conversation:

| Provider | Tools (as listed by the server) |
|---|---|
| AWS Knowledge MCP Server | `aws___search_documentation`, `aws___read_documentation`, `aws___list_regions`, `aws___get_regional_availability` |
| Microsoft Learn MCP Server | `microsoft_docs_search`, `microsoft_docs_fetch`, `microsoft_code_sample_search` |
| Google Developer Knowledge MCP | `search_documents`, `get_documents`, `answer_query` |

- **Rule (what to send)**: the text of each call goes to the provider. Send only general questions: a provider
  service name, a region, a feature name (for example "PrivateLink interface endpoint cross-region ap-northeast-1").
  Never put in a call the user's company name, database, table or column names, data values, account or project IDs,
  or service names.
- **Rule (scope)**: use these tools only for facts on the provider's side. ClickHouse facts come from the ClickHouse
  documentation. Cite the URL of each page you used.
- **Rule (not connected)**: if the PoC's provider has no knowledge tool in this conversation, say once that one can be
  added (docs/setup.md, step 4); adding it is the user's choice. Then go on: for each provider-side fact you leave to
  the user, give the provider's page for it, from the "Provider side" URLs above or from the provider's documentation
  home below, so the user knows where to check. Do not state a provider-side fact you have not read; mark it not
  verified.

| Provider | Documentation home | Topics the design usually needs |
|---|---|---|
| AWS | https://docs.aws.amazon.com/ | PrivateLink https://docs.aws.amazon.com/vpc/latest/privatelink/what-is-privatelink.html ; Amazon MSK https://docs.aws.amazon.com/msk/latest/developerguide/what-is-msk.html ; S3 data transfer https://aws.amazon.com/s3/pricing/ |
| Google Cloud | https://cloud.google.com/docs | Private Service Connect https://cloud.google.com/vpc/docs/private-service-connect ; Cloud Storage https://cloud.google.com/storage/docs |
| Azure | https://learn.microsoft.com/azure/ | Private Link https://learn.microsoft.com/azure/private-link/private-link-overview ; Event Hubs https://learn.microsoft.com/azure/event-hubs/event-hubs-about |
