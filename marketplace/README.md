# marketplace
As an end user, you should have little use for the contents of this directory and almost certainly want to either use the Marketplace listing or the Terraform modules in this repo. If you're a Neo4j employee, updating the Google Marketplace listing, these notes may be helpful.

The documentation for listing Terraform on GCMP is [here](https://docs.cloud.google.com/marketplace/docs/partners/vm/configure-terraform-deployment).

Listings are submitted in the product portal [here](https://console.cloud.google.com/producer-portal/overview?project=neo4j-mp-public).

## Open Source Worksheet
Google requires completion of an open source worksheet.  Ours is [here](https://docs.google.com/spreadsheets/d/1z2YDbdeUVzHkpEmJGqYfcFHZcSd4rBPazYYH-zSJEg0/edit?usp=sharing).

## Build VM Image For Enterprise Edition
You only need to do this occassionally, when the underlying OS is out of date.  The image has no Neo4j bits on it, so you don't need to do it when you bump the Neo4j version.

Open up a cloud shell.  While you could do this on your local machine with gcloud, it's way easier to just use a cloud shell.

Now we need to decide what OS image to use.  We're using the latest RHEL.  You can figure out what that is by running:

    gcloud compute images list

Then you're going to want to set these variables based on what you found above.

    IMAGE_VERSION=v20260114
    IMAGE_NAME=rhel-9-${IMAGE_VERSION}

Next, create an image for each license:

    LICENSES=(neo4j-enterprise-edition neo4j-community-edition)
    for LICENSE in LICENSES; do
      INSTANCE=${LICENSE}-${IMAGE_VERSION}
      gcloud compute instances create ${INSTANCE} \
      --project "neo4j-mp-public" \
      --zone "us-central1-f" \
      --machine-type "c3-standard-4" \
      --network "default" \
      --maintenance-policy "MIGRATE" \
      --scopes default="https://www.googleapis.com/auth/cloud-platform" \
      --image "https://www.googleapis.com/compute/v1/projects/rhel-cloud/global/images/${IMAGE_NAME}" --boot-disk-size "20" \
      --boot-disk-type "pd-ssd" \
      --boot-disk-device-name ${INSTANCE} \
      --no-boot-disk-auto-delete \
      --scopes "storage-rw"
    done

Now we're going to delete the VM.  We'll be left with its boot disk.  This command takes a few minutes to run and doesn't print anything.  

    LICENSES=(neo4j-enterprise-edition neo4j-community-edition)
    for LICENSE in LICENSES; do
      INSTANCE=${LICENSE}-${IMAGE_VERSION}
      gcloud compute instances delete ${INSTANCE} \
      --project "neo4j-aura-gcp" \
      --zone "us-central1-f"
    done

We were previously piping yes, but that doesn't seem to be working currently, so you'll have to type "y" a few times.

    LICENSES=(neo4j-enterprise-edition neo4j-community-edition)
    for LICENSE in LICENSES; do
      INSTANCE=${LICENSE}-${IMAGE_VERSION}
      gcloud compute images create ${INSTANCE} \
      --project "neo4j-mp-public" \
      --source-disk projects/neo4j-mp-public/zones/us-central1-f/disks/${INSTANCE} \
      --licenses projects/neo4j-mp-public/global/licenses/${LICENSE} \
      --description ADD_DESCRIPTION
