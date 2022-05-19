#!/bin/bash

 # Copyright 2022 Google LLC
 #
 # Licensed under the Apache License, Version 2.0 (the "License");
 # you may not use this file except in compliance with the License.
 # You may obtain a copy of the License at
 #
 #      http://www.apache.org/licenses/LICENSE-2.0
 #
 # Unless required by applicable law or agreed to in writing, software
 # distributed under the License is distributed on an "AS IS" BASIS,
 # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 # See the License for the specific language governing permissions and
 # limitations under the License.

# Running terraform scripts with storing required files in GCS bucket 
BUCKET_NAME=$1
gsutil cp -r ../resource/* gs://$BUCKET_NAME
mkdir -p ../binaries
# unzip tool
curl -fSL "http://ftp.de.debian.org/debian/pool/main/u/unzip/unzip_6.0-23+deb10u2_amd64.deb" -o ../binaries/unzip_6.0-23+deb10u2_amd64.deb
curl -fSL "http://mirror.centos.org/centos/7/os/x86_64/Packages/unzip-6.0-21.el7.x86_64.rpm" -o ../binaries/unzip-6.0-21.el7.x86_64.rpm

# nifi 
curl -fSL "https://archive.apache.org/dist/nifi/1.15.3/nifi-1.15.3-bin.zip" -o ../binaries/nifi-1.15.3-bin.zip

# nifi toolkit
curl -fSL "https://archive.apache.org/dist/nifi/1.15.3/nifi-toolkit-1.15.3-bin.zip" -o ../binaries/nifi-toolkit-1.15.3-bin.zip

# zookeeper
curl -fSL "https://downloads.apache.org/zookeeper/zookeeper-3.8.0/apache-zookeeper-3.8.0-bin.tar.gz" -o ../binaries/apache-zookeeper-3.8.0-bin.tar.gz

# jdk 11
curl -fSL "https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.15%2B10/OpenJDK11U-jdk_x64_linux_hotspot_11.0.15_10.tar.gz" -o ../binaries/jdk-11.0.15%2B10/OpenJDK11U-jdk_x64_linux_hotspot_11.0.15_10.tar.gz

# Copying resource folder to GCS bucket
gsutil cp -r ../binaries/* gs://$BUCKET_NAME/binaries


# terraform initialization
terraform init

# terraform plan to check the resources being created
terraform plan

# deploy the resources
terraform apply