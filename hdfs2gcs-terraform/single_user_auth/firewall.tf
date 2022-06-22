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

 // This file creates firewall rules for provisioned VPC network.

// Firewall rule for ssh access to cluster VMs

resource "google_compute_firewall" "allow-ssh" {
    
    name    = "allow-ssh"
    network = "${google_compute_network.default.name}"

    allow {
        protocol = "tcp"
        ports    = ["22"]
    }
    source_ranges = [
        "0.0.0.0/0"
    ]
    target_tags = ["nifi-host", "zookeeper", "nifi-ca"]
}

// Firewall rule for cluster VMs for internal communications
resource "google_compute_firewall" "allow-internal" {
    
    name    = "allow-internal"
    network = "${google_compute_network.default.name}"

    allow { 
        protocol = "icmp"
    }

    allow {
        protocol = "tcp"
        ports    = ["0-65535"]
    }

    allow {
        protocol = "udp"
        ports    = ["0-65535"]
    }

    source_ranges = [
        "${google_compute_subnetwork.default.ip_cidr_range}"
    ]
}
// Firewall rule for bastion host to access NIFI VMs through https
resource "google_compute_firewall" "allow-https" {
    
    name    = "allow-https"
    network = "${google_compute_network.default.name}"

    allow {
        protocol = "tcp"
        ports    = ["8443"]
    }
    
    target_tags  = ["nifi-host"]
    source_tags = ["bastionhost"]
}
// Firewall rule to open up RDP on bastion host Windows VM
resource "google_compute_firewall" "bastionhost-allow-rdp" {
    name = "bastionhost-allow-rdp"
    network = "${google_compute_network.default.name}"

    allow {
        protocol = "tcp"
        ports    = ["3389"]
    }
    source_ranges = [
        "0.0.0.0/0"
    ]

    target_tags = ["bastionhost"]
}

