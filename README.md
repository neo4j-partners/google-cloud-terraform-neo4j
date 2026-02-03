# google-cloud-terraform-neo4j
This repo contains Terraform modules that deploy Neo4j on Google Cloud.  There are templates for Enterprise Edition (EE) and Community Edition (CE).  These templates are used in two Google Cloud Marketplace listings:

* [Neo4j Enterprise Edition](https://console.cloud.google.com/marketplace/product/neo4j-mp-public/neo4j-enterprise-edition)
* Neo4j Community Edition

While deployable through the marketplace, it can also be useful to fork and customize the template to meet your needs.

To deploy this template from the command line, follow these instructions.

## Environment Setup

1. Ensure your default GCP project is set in gcloud CLI:
```bash
gcloud config set project YOUR_PROJECT_ID
```

2. Copy `terraform.tfvars.example` to `terraform.tfvars` and update the values

3. Initialize Terraform:

```bash
terraform init
```

4. Plan the deployment:

```bash
terraform plan
```

5. Apply the configuration:

```bash
terraform apply
```
