#!/bin/sh

for EDITION in "ce" "ee"; do
  rm $EDITION-archive.zip
  mkdir tmp

  cp ../$EDITION/* tmp
  cd tmp
  rm terraform.tfvars

  zip -r -X $EDITION-archive.zip *
  mv $EDITION-archive.zip ../
  cd ..
  rm -rf tmp
done

gcloud config set project neo4j-mp-public
gcloud storage cp *.zip gs://neo4j-terraform-marketplace/
