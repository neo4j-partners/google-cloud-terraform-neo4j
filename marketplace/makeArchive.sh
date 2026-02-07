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