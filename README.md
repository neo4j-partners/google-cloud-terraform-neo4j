# Neo4j EE and CE on GCP

Neo4j Enterprise and Community editions can be easily deployed on Virtual Machines in Google Cloud Platform (GCP) by using the following GCP Marketplace listings:

* [Neo4j Enterprise Edition](https://console.cloud.google.com/marketplace/product/neo4j-mp-public/neo4j-enterprise-edition)
* [Neo4j Community Edition](https://console.cloud.google.com/marketplace/product/neo4j-mp-public/neo4j-community-edition)


## Neo4j Terraform deployment module

The GCP Marketplace listings use HashiCorp Terraform IaC tool to deploy Neo4j Community and Enterprise Edition on GCP provided in this repository.

HashiCorp Terraform is an infrastructure deployment module, which automates the creation and management of Google Cloud resources.
It takes several parameters as inputs, deploys a set of cloud resources, and provides outputs that can be used to connect to a Neo4j DBMS.
The  Neo4j Terraform deployment module always installs the latest available version.

The repository structure is as follows:

```
google-cloud-terraform-neo4j/
├── ce/                           # Community edition module
│   ├── main.tf                   # Main module configuration
│   ├── marketplace_test.tfvars   # Test configurations
|   ├── metadata.display.yaml     # GCP Marketplace display metadata
|   ├── metadata.yaml             # GCP Marketplace metadata
│   ├── outputs.tf                # Module outputs
|   ├── startup.sh                # Startup script for Neo4j
│   ├── terraform.tfvars          # Environment variables file
│   ├── variables.tf              # Module variables
│   └── versions.tf               # Module provider requirements
├── ee/                           # Enterprise edition module
│   ├── main.tf                   # Main module configuration
│   ├── marketplace_test.tfvars   # Test configurations
|   ├── metadata.display.yaml     # GCP Marketplace display metadata
|   ├── metadata.yaml             # GCP Marketplace metadata
│   ├── outputs.tf                # Module outputs
|   ├── startup.sh                # Startup script for Neo4j
│   ├── terraform.tfvars          # Environment variables file
│   ├── variables.tf              # Module variables
│   └── versions.tf               # Module provider requirements
├── marketplace/
|   ├── logo.png                  # Logo for GCP Marketplace
|   ├── README.md                 # Notes for Neo4j employees who want to update the listings
|   └── updateArchive.sh          # Script that updates the listings
├── LICENSE                       # TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION
└── README.md                     # This readme
```

## Important considerations

* The deployment of cloud resources incurs costs.
Refer to the [GCP pricing calculator](https://cloud.google.com/products/calculator) for more information.

* The Neo4j Terraform module deploys a new VPC, containing a single subnet based in the requested region.
Unlike Azure and AWS where subnets are aligned to specific zones, GCP subnets are regional (and VPCs are global).

* The Neo4j Terraform module uses an Instance Group to deploy VM instances.
To stop a VM managed by a group, you must first remove it from that group.

* Instances can be connected via SSH, using SSH-in-browser (via the GCP console).
Click the *SSH* button in the GCP console.

## Deployment prerequisites

Before deploying Neo4j using the Terraform module, ensure you have the following prerequisites in place:

<!--The provided Terraform version might need to be updated as the latest is 1.15.8 -->
* Terraform 1.2.0 or newer.
See the [official Terraform installation guide](https://developer.hashicorp.com/terraform/install) for instructions.
* Google Cloud SDK
* A GCP project with billing enabled
* Appropriate permissions to create resources in GCP
* Default project configured in `gcloud` CLI (`gcloud config set project YOUR_PROJECT_ID`)

## Licensing

Installing and starting Neo4j from the GCP marketplace constitutes an acceptance of the Neo4j license agreement.
When deploying Neo4j, you are required to confirm that you either have an Enterprise license or accept the terms of the Neo4j evaluation license.

<!-- If you require the Enterprise version of Bloom, you need to provide a key issued by Neo4j as this is required during the installation.

To obtain a valid license for Bloom reach out to your Neo4j account representative or get in touch using the [contact form](https://neo4j.com/contact-us/). -->


## Deploy from GCP Marketplace

1. Visit the [Neo4j Enterprise listing on GCP Marketplace](https://console.cloud.google.com/marketplace/product/neo4j-mp-public/neo4j-enterprise-edition).
2. Click **Get Started**.
3. Select your GCP project.
4. Agree on terms to deploy the product.
5. Click **Deploy**.
6. Configure the deployment parameters.
7. Review and click **Deploy**.

## Use the module directly

Alternatively, you can deploy this module from the command line.

1. Make a clone of this repository:

    ```bash
    git clone https://github.com/neo4j-partners/google-cloud-terraform-neo4j.git
    cd google-cloud-terraform-neo4j
    ```

2. Ensure your default GCP project is set in gcloud CLI:

    ```bash
    gcloud config set project YOUR_PROJECT_ID
    ```

3. Open the directory of the edition you want to deploy, for example, Enterprise:

    ```bash
    cd ee
    ```

4. Initialize Terraform:

    ```bash
    terraform init
    ```

5. Plan the deployment:

    ```bash
    terraform plan
    ```

6. If it looks good, you can run apply:

    ```bash
    terraform apply
    ```

### Deployed cloud resources

The environment created by the Terraform module consists of the following GCP resources:

* A VPC network and subnetwork (optional).
<!-- * Firewall rules for internal and external access. -->
* Neo4j VMs with attached persistent disks.
* Configures Neo4j for standalone or clustered operation.

### Template outputs

After the installation finishes successfully, the Terraform module provides the following outputs:

* `neo4j_browser_url` - URL to access Neo4j Browser.
* `neo4j_bolt_endpoint` - Bolt URL to connect to Neo4j.


> If the Neo4j Browser is not coming up, there is a good chance something is not right in your deployment. One thing to investigate is serial output from the VM. If that looks good, the next place to check out is `/var/log/neo4j/debug.log`.


<!-- ### Testing the module NEEDS TO BE UPDATED

The module includes test configurations in the _test/_ directory, which can be used to validate the deployment.
The following test scripts are provided:

* `verify_module.sh`: Basic verification for GCP Marketplace
*  `test_deployment.sh`: Comprehensive deployment testing using marketplace_test.tfvars

The test script performs thorough checks to verify:

* All instances are properly deployed.
* Neo4j services are running and accessible.
* Neo4j Browser and Bolt interfaces are operational.
* Cluster configuration is properly set up. -->

## Delete deployment and destroy resources

To delete the deployment and destroy all associated resources, you can use the following Terraform command:

```bash
terraform destroy
```

This command will prompt you to confirm the destruction of all resources defined in your Terraform configuration.
Review the proposed changes carefully before confirming.
For detailed information on the `terraform destroy` command, refer to the [official Terraform documentation](https://developer.hashicorp.com/terraform/cli/commands/destroy).