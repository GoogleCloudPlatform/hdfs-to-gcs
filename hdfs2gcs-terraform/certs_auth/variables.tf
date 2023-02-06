/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
// Variables and default values 


variable "project-id" {
    description = "The GCP project to use for integration tests"
    type        = string
    default     = "test-sandbox"
}

variable "region" {
    description = "The GCP region to create and test resources in"
    type        = string
    default     = "us-west1"
}

variable "zone" {
    description = "The GCP zone to create and test resources in"
    type        = string
    default     = "us-west1-a"
}

variable "disk-type" {
    description = "The GCP disk type. Example: pd-standard"
    type        = string
    default     = "pd-ssd"
}

variable "disk-size" {
    description = "The GCP disk size specified in GB"
    type        = string
    default     = "1000"
}

variable "image" {
    description = "Source disk image."
    type        = string
    default     = "centos-7-v20220406"
}

variable "instance-count-nifi" {
    description = "Number of VM instances in NIFI cluster"
    type        = string
    default     = "3"
}

variable "instance-count-zk" {
    description = "Number of Zookeeper instances"
    type        = string
    default     = "3"
}

variable "nifi-machine-type" {
    description = "Instance machine type"
    type        = string
    default     = "n1-highcpu-16"
}

variable "nifi-ca-machine-type" {
    description = "Instance machine type"
    type        = string
    default     = "f1-micro"
}

variable "zookeeper-machine-type" {
    description = "Instance machine type"
    type        = string
    default     = "f1-micro"
}

variable "network-name" {
    description = "VPC network name"
    type        = string
    default     = "nifi-network"
}

variable "network-ip-cidr-range" {
    description = "VPC subnetwork IP range"
    type        = string
    default     = "10.138.0.0/20"
}

variable "nifi-version" {
    description = "NIFI binaries version"
    type        = string
    default     = "1.15.3"
}

variable "zk-version" {
    description = "Zookeeper binary version"
    type        = string
    default     = "3.8.0"
}

variable "nifi-bucket" {
    description = "GCP bucket name"
    type        = string
    default     = "gs://nifi-binaries"
}

variable "nifi-hostname"{
    description = "NIFI VM hostnames. Example: nifi-1, nifi-2"
    type        = string
    default     = "nifi"

}

variable "zookeeper-hostname" {
    description = "Zookeeper VM hostnames. Example: nifi-zookeeper-1, nifi-zookeeper-2"
    type        = string
    default     = "nifi-zookeeper"
}

variable "nifi-ca-hostname" {
    description = "The hostname for NIFI certificate authority server"
    type        = string
    default     = "nifi-ca"
}

variable "ca-token" {
    description = "The token to use to prevent MITM between the NiFi CA client and the NiFi CA server (must be at least 16 bytes long)"
    type        = string
    default     = "ThisPasswordIsNotSecure"
}

variable "sensitivepropskey" {
    description = "Key that will be used for encrypting the sensitive properties in the flow definition (ex: ThisIsAVeryBadPass3word)"
    type        = string
    default     = "hggjgjgjggewzQjhajhfaf="   
}

variable "cert-password" {
    description = "The password used for keystore, truststore and key-password "
    type        = string
    default     = "testtesttest"
}

variable "nifi-path" {
    description = "The directory on NIFI VMs where the binaries are insalled"
    type        = string
    default     = "/opt"
}

variable "bh-hostname" {
    description = "The hostname for Bastion host VM"
    type        = string
    default     = "bh-nifi"
}

 variable "jdkpackage" {
     description = ""
     type = string
     default = "OpenJDK11U-jdk_x64_linux_hotspot_11.0.15_10.tar.gz"
 }