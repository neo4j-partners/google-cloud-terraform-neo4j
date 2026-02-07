# marketplace
As an end user, you should have little use for the contents of this directory and almost certainly want to either use the Marketplace listing or the Terraform modules in this repo. If you're a Neo4j employee, updating the Google Marketplace listing, these notes may be helpful.

* VM Image doc is [here](https://docs.cloud.google.com/marketplace/docs/partners/vm/build-vm-image).  This also describes how licenses are created.  Those are created once and are reusable for the lifetime of the listing.
* The documentation for listing Terraform on GCMP is [here](https://docs.cloud.google.com/marketplace/docs/partners/vm/configure-terraform-deployment).
* Listings are submitted in the product portal [here](https://console.cloud.google.com/producer-portal/overview?project=neo4j-mp-public).

## Open Source Worksheet
Google requires completion of an open source worksheet.  Ours is [here](https://docs.google.com/spreadsheets/d/1z2YDbdeUVzHkpEmJGqYfcFHZcSd4rBPazYYH-zSJEg0/edit?usp=sharing).

## Updating the Listing
To submit an updated listing, run ./makeArchive.sh.  You'll then need to upload those two archives to the neo4j-terraform-marketplace bucket in neo4j-mp-public.

After that you can link the archive in the Producer Portal [here](https://console.cloud.google.com/producer-portal/overview?project=neo4j-mp-public) and hit submit.

## Build VM Image For Enterprise Edition
You only need to do this occassionally, when the underlying OS is out of date.  The image has no Neo4j bits on it, so you don't need to do it when you bump the Neo4j version.

Open up a cloud shell.  While you could do this on your local machine with gcloud, it's way easier to just use a cloud shell.

Be sure you're in the marketplace publisher project.

    gcloud config set project neo4j-mp-public

Now we need to decide what OS image to use.  We're using the latest Cent OS.  You can figure out what that is by running:

    gcloud compute images list | grep centos

Then you're going to want to set these variables based on what you found above.

    IMAGE_VERSION=v20260126
    IMAGE_NAME=centos-stream-10-${IMAGE_VERSION}

Next, create an image for each license:

    for EDITION in "neo4j-community-edition" "neo4j-enterprise-edition"; do
      gcloud compute instances create ${EDITION} \
      --project "neo4j-mp-public" \
      --zone "us-central1-f" \
      --machine-type "n4-standard-4" \
      --network "default" \
      --maintenance-policy "MIGRATE" \
      --scopes default="https://www.googleapis.com/auth/cloud-platform" \
      --image "https://www.googleapis.com/compute/v1/projects/centos-cloud/global/images/${IMAGE_NAME}" --boot-disk-size "20" \
      --boot-disk-type "hyperdisk-balanced" \
      --boot-disk-device-name ${EDITION} \
      --no-boot-disk-auto-delete \
      --scopes "storage-rw"
    done

Now we're going to delete the VM.  We'll be left with its boot disk.  We were previously piping yes, but that doesn't seem to be working currently, so you'll have to type "y" a few times.

    for EDITION in "neo4j-community-edition" "neo4j-enterprise-edition"; do
      gcloud compute instances delete ${EDITION} \
      --project "neo4j-mp-public" \
      --zone "us-central1-f"
    done

Now we need to make images and add the licenses to each image.  The license is what Google users for metering.

    create_image() {
      gcloud compute images create neo4j-enterprise-edition \
      --project "neo4j-mp-public" \
      --source-disk projects/neo4j-mp-public/zones/us-central1-f/disks/${EDITION} \
      --licenses projects/neo4j-mp-public/global/licenses/${LICENSE} \
      --description ADD_DESCRIPTION
    }

    EDITION=neo4j-community-edition
    LICENSE=cloud-marketplace-c48d0eea1bfd511e-df1ebeb69c0ba664
    create_image

    EDITION=neo4j-enterprise-edition
    LICENSE=cloud-marketplace-10bbf7768486af4b-df1ebeb69c0ba664
    create_image

We've orphaned two disks.  Be sure to clean those up in the console.
