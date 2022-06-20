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

# Copying resource folder to GCS bucket
gsutil cp -r ../resource/* gs://$BUCKET_NAME

# terraform initialization
terraform init

# terraform plan to check the resources being created
terraform plan

# deploy the resources
terraform apply