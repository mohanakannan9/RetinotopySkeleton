#!/bin/bash

./RetinotopyAnalysis.sh \
  --subject=123456 \
  --stimulus-location-file=/henrietta/hippo \
  --image-files="hello.nii.gz@there.nii.gz@dolly.nii.gz" \
  --offset-files="hello_info.m@there_info.m@EMPTY"