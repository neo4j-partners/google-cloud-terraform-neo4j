# google-cloud-terraform-neo4j
This repo contains Terraform modules that deploy Neo4j on Google Cloud.  There are templates for Enterprise Edition (EE) and Community Edition (CE).  These templates are used in two Google Cloud Marketplace listings:

* [Neo4j Enterprise Edition](https://console.cloud.google.com/marketplace/product/neo4j-mp-public/neo4j-enterprise-edition)
* [Neo4j Community Edition](https://console.cloud.google.com/marketplace/product/neo4j-mp-public/neo4j-community-edition)

While deployable through the marketplace, it can also be useful to fork and customize the template to meet your needs.

To deploy this template from the command line, follow these instructions.

## Architecture
These templates deploy an instance group with a load balancer in front of it.

## Deployment
You can run these modules locally.  However, Google Cloud provides a preconfigured Cloud Shell that is an easier way to get started.  Navigate to the [Cloud Console](https://console.cloud.google.com/) and open the cloud shell in the upper right.

Now let's make a clone of this repo:

    git clone https://github.com/neo4j-partners/google-cloud-terraform-neo4j.git
    cd google-cloud-terraform-neo4j

Pick either ce or ee.  Go to the appropriate director.  For this example, I'll use ee:

    cd ee

Set up terraform

    terraform init

Show the plan for the deployment:

    terraform plan

If that looks good, you can run apply:

    terraform apply

## Deleting your Deployment
To delete your deployment you can either run:

    terraform detroy

## Debugging
If the Neo4j Browser isn't coming up, there's a good chance something isn't right in your deployment.  One thing to investigate is console output from the VM.  If that looks good, the next place to check out is `/var/log/neo4j/debug.log`.
