#!/bin/bash

./RetinotopyAnalysis.sh \
  --subject=123456 \
  --movie-files="movie1.mat@movie2.mat@movie3.mat@movie4.mat@movie5.mat" \
  --image-files="hello.nii.gz@there.nii.gz@dolly.nii.gz" \
  --behavior-files="hello_behavior.xml@there_behavior.xml@EMPTY"